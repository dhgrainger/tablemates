# validates :cover_image, image_attachment: { max_size: 5.megabytes }
#
# The type is sniffed from the uploaded file's bytes — neither the filename
# nor the content type the browser claimed is trusted.
class ImageAttachmentValidator < ActiveModel::EachValidator
  CONTENT_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze

  def validate_each(record, attribute, attachment)
    return unless attachment.attached?

    unless CONTENT_TYPES.include?(content_type_of(record, attribute, attachment))
      record.errors.add(attribute, "must be a PNG, JPEG, WebP or GIF image")
    end

    max_size = options.fetch(:max_size)
    if attachment.blob.byte_size > max_size
      record.errors.add(attribute, "is too big (max #{max_size / 1.megabyte} MB)")
    end
  end

  private
    def content_type_of(record, attribute, attachment)
      io = pending_io(record, attribute)
      return attachment.blob.content_type unless io

      io.rewind
      Marcel::MimeType.for(io).tap { io.rewind }
    end

    # The not-yet-stored upload, if this attachment is being changed.
    def pending_io(record, attribute)
      attachable = record.attachment_changes[attribute.to_s]&.attachable

      if attachable.respond_to?(:tempfile)
        attachable.tempfile
      elsif attachable.is_a?(Hash)
        attachable[:io]
      end
    end
end
