# The one place dollars-as-text and integer cents are converted.
# Money is always integer cents (USD) — no floats anywhere.
module Money
  MAX_CENTS = 1_000_000 # $10,000.00
  DOLLARS = /\A(\d{1,7})(?:\.(\d{1,2}))?\z/

  # "12.5" / "$1,200" / " 7 " => cents. Blank => 0. Anything else => nil.
  def self.parse_cents(input)
    text = input.to_s.delete("$, ").strip
    return 0 if text.empty?

    match = DOLLARS.match(text)
    return nil unless match

    match[1].to_i * 100 + match[2].to_s.ljust(2, "0").to_i
  end

  # 123456 => "1,234.56"
  def self.decimal(cents)
    dollars, remainder = cents.abs.divmod(100)
    whole = dollars.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
    "#{'-' if cents.negative?}#{whole}.#{remainder.to_s.rjust(2, '0')}"
  end

  # 123456 => "$1,234.56"
  def self.format(cents)
    decimal(cents).sub(/\A(-?)/, '\1$')
  end
end
