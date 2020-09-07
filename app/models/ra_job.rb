class RaJob < ActiveRecord::Base
  STATUS = { 0 => "NO RUNNING", 1 => "RUNNING", 2 => "ERROR", 3 => "STOP", 4 => "DONE" }

  after_create :create_dir
  serialize :params

  def start!(async = false)
    backup_dir if self.run_count > 0
    if async
      command = "/bin/bash -c 'cd #{Rails.root} && bundle exec rake rails_admin:run_job ID=#{self.id} RAILS_ENV=#{Rails.env} --trace > #{Rails.root}/log/rake.log'"
      fork {exec command}
    else
      "Job::#{self.name}".constantize.process(self)
      Rails.logger.debug "*" * 100
      Rails.logger.debug "Running Job #{command}"
      Rails.logger.debug "*" * 100
      self.run_count += 1
      self.save
    end
  end

  def mark_as_error!
    self.update_column(:status, 2)
  end

  def mark_as_done!
    self.update_column(:status, 4)
  end

  def update_progress(_progress)
    _progress = 100 if _progress > 100
    self.update_column(:status, 4) if _progress == 100
    `echo #{_progress} > #{dir}/progress`
  end

  def update_logger(text)
    file = File.open("#{dir}/logger", "a")
    file.puts text
    file.close
  end

  def progress
    File.read("#{dir}/progress")
  end

  def logger
    File.read("#{dir}/logger")
  end

  def create_dir
    `mkdir -p #{dir}`
    `touch #{dir}/logger`
    `touch #{dir}/progress`
    `mkdir #{dir}/params`
  end

  def backup_dir
    timestamp = Time.now.strftime("%Y-%m-%d-%H:%M:%S")
    `mkdir #{dir}/#{timestamp}`
    `mv #{dir}/logger #{dir}/#{timestamp}/`
    `mv #{dir}/progress #{dir}/#{timestamp}/`
    `touch #{dir}/logger`
    `touch #{dir}/progress`
  end

  def dir
    "#{Rails.root}/public/system/job/#{self.id}"
  end

  def set_params!(_params)
    return false unless _params
    raise "Should create the job before set params!" if self.new_record?
    formated_params = {}
    _params.each do |k, v|
      if v.class == ActionDispatch::Http::UploadedFile
        `cp #{v.tempfile.path} #{dir}/params/#{v.original_filename}`
        formated_params[k] = "#{dir}/params/#{v.original_filename}"
      else
        formated_params[k] = v
      end
    end
    self.params = formated_params
    self.save
  end

  def formated_status_name
    RaJob::STATUS[self.status.to_i]
  end
end
