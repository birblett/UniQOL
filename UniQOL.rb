module UniQOL

  def self.asset_relative(path) = "UniQOL/UniQOLAssets/#{path}"

  def self.asset(path) = UniLib.path "UniQOL/UniQOLAssets/#{path}"

  def self.dir_load(d) = UniLib.dir_load "UniQOL/#{d}"

end

UniQOL.dir_load("Modules")
UniQOL.dir_load("Modules/Reborn") if Reborn
UniQOL.dir_load("Modules/Rejuv") if Rejuv