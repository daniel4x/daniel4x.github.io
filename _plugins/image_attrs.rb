# frozen_string_literal: true

# After each page renders, give local <img> tags the things markdown can't:
# intrinsic width/height (no layout shift) and lazy loading. Tags that already
# set an attribute keep it, so templates can opt the hero image out of lazy.

module ImageAttrs
  module_function

  def process(site, html)
    html.gsub(/<img\b[^>]*>/) do |tag|
      src = tag[/\bsrc="([^"]+)"/, 1].to_s.sub(/\A#{Regexp.escape(site.baseurl.to_s)}/, "")
      extra = +""
      if src.start_with?("/assets/") && tag !~ /\bwidth=/
        width, height = dimensions(File.join(site.source, src))
        extra << %( width="#{width}" height="#{height}") if width
      end
      extra << %( loading="lazy") unless tag =~ /\bloading=/
      extra << %( decoding="async") unless tag =~ /\bdecoding=/
      tag.sub(/\s*\/?>\z/, "#{extra}>")
    end
  end

  def dimensions(path)
    return unless File.file?(path)

    File.open(path, "rb") do |file|
      head = file.read(24)
      if head.start_with?("\x89PNG".b)
        head[16, 8].unpack("NN")
      elsif head.start_with?("\xFF\xD8".b)
        jpeg_dimensions(file)
      end
    end
  end

  # Walk JPEG segments until a start-of-frame marker, which holds the size.
  def jpeg_dimensions(file)
    file.seek(2)
    loop do
      marker, type, length = file.read(4)&.unpack("CCn")
      return unless marker == 0xFF

      if (0xC0..0xCF).cover?(type) && ![0xC4, 0xC8, 0xCC].include?(type)
        height, width = file.read(5).unpack("xnn")
        return [width, height]
      end
      file.seek(length - 2, IO::SEEK_CUR)
    end
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html"

  doc.output = ImageAttrs.process(doc.site, doc.output)
end
