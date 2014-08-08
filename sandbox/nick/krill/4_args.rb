class Protocol
  def arguments
    { a: 1,
      b: banana
    }
  end

  def main
    # Can I unpack multiple?
    a, b = input[:a], input[:b]
    show {
      note a
      note b
    }
  end
end
