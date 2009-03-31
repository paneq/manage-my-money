module FileRecognizer
  def recognize_file(content, file_name)
    return :inteligo if file_name.downcase.ends_with? 'xml'
    return :mbank if file_name.downcase.ends_with? 'csv'
    return nil
  end
end