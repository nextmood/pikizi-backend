# see http://www.fngtps.com/2007/10/patching-rails-edge-to-stay-bug-free

task :patch => 'patches:apply'

namespace :patches do
  desc "Apply all patches from vendor/patches to root"
  task :apply do
    Dir.chdir(RAILS_ROOT) do
      Dir["vendor/patches/*"].each do |patch|
        system "patch -p0 < \"#{patch}\""
      end
    end
  end

  desc "Revert all patches applied in vendor/plugins and vendor/rails" +
       "through SVN"
  task :revert do
    system "svn revert --recursive vendor/plugins vendor/rails"
  end
end