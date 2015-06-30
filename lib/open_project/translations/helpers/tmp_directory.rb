module TmpDirectory
  def create_tmp_directory(delete: nil)
    tmp_path = File.join(FileUtils.pwd, 'tmp')
    if delete
      FileUtils.rm_rf tmp_path
    end
    FileUtils.mkdir_p tmp_path
    tmp_path
  end

  def remove_tmp_directory(tmp_path)
    FileUtils.rm_rf tmp_path
  end
end
