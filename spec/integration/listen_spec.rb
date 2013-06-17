# encoding: UTF-8
require 'spec_helper'

# TODO
def listen(paths, options = {})
  @changes = {}
  listener = Listen.to(*paths, options) do |modified, added, removed|
    @changes = { modified: modified, added: added, removed: removed }
  end
  listener.start
  sleep 2 # wait adapter
  yield
  sleep 0.2 # wait for changes
  listener.stop
  @changes
end

describe "Listen" do
  let(:path) { Pathname.new(Dir.pwd) }
  let(:file_path) { path.join('file.rb').to_s }
  around { |example| fixtures { |path| example.run } }

  context "force_polling option to true" do
    let(:options) { { force_polling: true } }

    context "nothing in listen dir" do
      it "listens to file addition" do
        listen(path, options) {
          touch file_path
        }.should eq({ modified: [], added: [file_path], removed: [] })
      end
    end

    context "file in listen dir" do
      around { |example| touch file_path; example.run }

      it "listens to file modification" do
        listen(path, options) {
          touch file_path
        }.should eq({ modified: [file_path], added: [], removed: [] })
      end

      it "listens to file removal" do
        listen(path, options) {
          rm file_path
        }.should eq({ modified: [], added: [], removed: [file_path] })
      end
    end
  end
end

#   describe '#fetch_changes' do
#     context 'with single file changes' do
#       context 'when a file is created' do
#         it 'detects the added file' do
#           fixtures do |path|
#             modified, added, removed = changes(path) do
#               touch 'new_file.rb'
#             end

#             added.should =~ %w(new_file.rb)
#             modified.should be_empty
#             removed.should be_empty
#           end
#         end

#         it 'stores the added file in the record' do
#           fixtures do |path|
#             changes(path) do
#               @record.paths.should be_empty

#               touch 'new_file.rb'
#             end

#             @record.paths[path]['new_file.rb'].should_not be_nil
#           end
#         end

#         context 'given a new created directory' do
#           it 'detects the added file' do
#             fixtures do |path|
#               modified, added, removed = changes(path) do
#                 mkdir 'a_directory'
#                 touch 'a_directory/new_file.rb'
#               end

#               added.should =~ %w(a_directory/new_file.rb)
#               modified.should be_empty
#               removed.should be_empty
#             end
#           end

#           it 'stores the added directory and file in the record' do
#             fixtures do |path|
#               changes(path) do
#                 @record.paths.should be_empty

#                 mkdir 'a_directory'
#                 touch 'a_directory/new_file.rb'
#               end

#               @record.paths[path]['a_directory'].should_not be_nil
#               @record.paths["#{path}/a_directory"]['new_file.rb'].should_not be_nil
#             end
#           end
#         end

#         context 'given an existing directory' do
#           context 'with recursive option set to true' do
#             it 'detects the added file' do
#               fixtures do |path|
#                 mkdir 'a_directory'

#                 modified, added, removed = changes(path, recursive: true) do
#                   touch 'a_directory/new_file.rb'
#                 end

#                 added.should =~ %w(a_directory/new_file.rb)
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end

#             context 'with an ignored directory' do
#               it "doesn't detect the added file" do
#                 fixtures do |path|
#                   mkdir 'ignored_directory'

#                   modified, added, removed = changes(path, ignore: %r{^ignored_directory/}, recursive: true) do
#                     touch 'ignored_directory/new_file.rb'
#                   end

#                   added.should be_empty
#                   modified.should be_empty
#                   removed.should be_empty
#                 end
#               end

#               it "doesn't detect the added file when it's asked to fetch the changes of the ignored directory"do
#                 fixtures do |path|
#                   mkdir 'ignored_directory'

#                   modified, added, removed = changes(path, paths: ["#{path}/ignored_directory"], ignore: %r{^ignored_directory/}, recursive: true) do
#                     touch 'ignored_directory/new_file.rb'
#                   end

#                   added.should be_empty
#                   modified.should be_empty
#                   removed.should be_empty
#                 end
#               end
#             end
#           end

#           context 'with recursive option set to false' do
#             it "doesn't detect deeply-nested added files" do
#               fixtures do |path|
#                 mkdir 'a_directory'

#                 modified, added, removed = changes(path, recursive: false) do
#                   touch 'a_directory/new_file.rb'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end

#         context 'given a directory with subdirectories' do
#           it 'detects the added file' do
#             fixtures do |path|
#               mkdir_p 'a_directory/subdirectory'

#               modified, added, removed = changes(path, recursive: true) do
#                 touch 'a_directory/subdirectory/new_file.rb'
#               end

#               added.should =~ %w(a_directory/subdirectory/new_file.rb)
#               modified.should be_empty
#               removed.should be_empty
#             end
#           end

#           context 'with an ignored directory' do
#             it "doesn't detect added files in neither the directory nor the subdirectory" do
#               fixtures do |path|
#                 mkdir_p 'ignored_directory/subdirectory'

#                 modified, added, removed = changes(path, ignore: %r{^ignored_directory/}, recursive: true) do
#                   touch 'ignored_directory/new_file.rb'
#                   touch 'ignored_directory/subdirectory/new_file.rb'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end
#       end

#       context 'when a file is modified' do
#         it 'detects the modified file' do
#           fixtures do |path|
#             touch 'existing_file.txt'

#             modified, added, removed = changes(path) do
#               small_time_difference
#               touch 'existing_file.txt'
#             end

#             added.should be_empty
#             modified.should =~ %w(existing_file.txt)
#             removed.should be_empty
#           end
#         end

#         context 'during the same second at which we are checking for changes' do
#           before { ensure_same_second }

#           # The following test can only be run on systems that report
#           # modification times in milliseconds.
#           it 'always detects the modified file the first time', if: described_class::HIGH_PRECISION_SUPPORTED do
#             fixtures do |path|
#               touch 'existing_file.txt'

#               modified, added, removed = changes(path) do
#                 small_time_difference
#                 touch 'existing_file.txt'
#               end

#               added.should be_empty
#               modified.should =~ %w(existing_file.txt)
#               removed.should be_empty
#             end
#           end

#           context 'when a file is created and then checked for modifications at the same second - #27' do
#             # This issue was the result of checking a file for content changes when
#             # the mtime and the checking time are the same. In this case there
#             # is no checksum saved, so the file was reported as being changed.
#             it 'does not report any changes' do
#               fixtures do |path|
#                 touch 'a_file.rb'

#                 modified, added, removed = changes(path)

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end

#           it 'detects the modified file the second time if the content have changed' do
#             fixtures do |path|
#               touch 'existing_file.txt'

#               # Set sha1 path checksum
#               changes(path) do
#                 touch 'existing_file.txt'
#               end

#               changes(path) do
#                 small_time_difference
#                 touch 'existing_file.txt'
#               end

#               modified, added, removed = changes(path, use_last_record: true) do
#                 open('existing_file.txt', 'w') { |f| f.write('foo') }
#               end

#               added.should be_empty
#               modified.should =~ %w(existing_file.txt)
#               removed.should be_empty
#             end
#           end

#           it "doesn't checksum the contents of local sockets (#85)", unless: windows? do
#             require 'socket'
#             fixtures do |path|
#               Digest::SHA1.should_not_receive(:file)
#               socket_path = File.join(path, "unix_domain_socket")
#               server = UNIXServer.new(socket_path)
#               modified, added, removed = changes(path) do
#                 t = Thread.new do
#                   client = UNIXSocket.new(socket_path)
#                   client.write("foo")
#                 end
#                 t.join
#               end
#               added.should be_empty
#               modified.should be_empty
#               removed.should be_empty
#             end
#           end

#           it "doesn't detects the modified file the second time if just touched - #62", unless: described_class::HIGH_PRECISION_SUPPORTED do
#             fixtures do |path|
#               touch 'existing_file.txt'

#               # Set sha1 path checksum
#               changes(path) do
#                 touch 'existing_file.txt'
#               end

#               changes(path, use_last_record: true) do
#                 small_time_difference
#                 open('existing_file.txt', 'w') { |f| f.write('foo') }
#               end

#               modified, added, removed = changes(path, use_last_record: true) do
#                 touch 'existing_file.txt'
#               end

#               added.should be_empty
#               modified.should be_empty
#               removed.should be_empty
#             end
#           end

#           it "adds the path in the paths checksums if just touched - #62" do
#             fixtures do |path|
#               touch 'existing_file.txt'

#               changes(path) do
#                 small_time_difference
#                 touch 'existing_file.txt'
#               end

#               @record.sha1_checksums["#{path}/existing_file.txt"].should_not be_nil
#             end
#           end

#           it "deletes the path from the paths checksums" do
#             fixtures do |path|
#               touch 'unnecessary.txt'

#               changes(path) do
#                 @record.sha1_checksums["#{path}/unnecessary.txt"] = 'foo'

#                 rm 'unnecessary.txt'
#               end

#               @record.sha1_checksums["#{path}/unnecessary.txt"].should be_nil
#             end
#           end
#         end

#         context 'given a hidden file' do
#           it 'detects the modified file' do
#             fixtures do |path|
#               touch '.hidden'

#               modified, added, removed = changes(path) do
#                 small_time_difference
#                 touch '.hidden'
#               end

#               added.should be_empty
#               modified.should =~ %w(.hidden)
#               removed.should be_empty
#             end
#           end
#         end

#         context 'given a file mode change' do
#           it 'does not detect the mode change' do
#             fixtures do |path|
#               touch 'run.rb'

#               modified, added, removed = changes(path) do
#                 small_time_difference
#                 chmod 0777, 'run.rb'
#               end

#               added.should be_empty
#               modified.should be_empty
#               removed.should be_empty
#             end
#           end
#         end

#         context 'given an existing directory' do
#           context 'with recursive option set to true' do
#             it 'detects the modified file' do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/existing_file.txt'

#                 modified, added, removed = changes(path, recursive: true) do
#                   small_time_difference
#                   touch 'a_directory/existing_file.txt'
#                 end

#                 added.should be_empty
#                 modified.should =~ %w(a_directory/existing_file.txt)
#                 removed.should be_empty
#               end
#             end
#           end

#           context 'with recursive option set to false' do
#             it "doesn't detects the modified file" do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/existing_file.txt'

#                 modified, added, removed = changes(path, recursive: false) do
#                   small_time_difference
#                   touch 'a_directory/existing_file.txt'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end

#         context 'given a directory with subdirectories' do
#           it 'detects the modified file' do
#             fixtures do |path|
#               mkdir_p 'a_directory/subdirectory'
#               touch   'a_directory/subdirectory/existing_file.txt'

#               modified, added, removed = changes(path, recursive: true) do
#                 small_time_difference
#                 touch 'a_directory/subdirectory/existing_file.txt'
#               end

#               added.should be_empty
#               modified.should =~ %w(a_directory/subdirectory/existing_file.txt)
#               removed.should be_empty
#             end
#           end

#           context 'with an ignored subdirectory' do
#             it "doesn't detect the modified files in neither the directory nor the subdirectory" do
#               fixtures do |path|
#                 mkdir_p 'ignored_directory/subdirectory'
#                 touch   'ignored_directory/existing_file.txt'
#                 touch   'ignored_directory/subdirectory/existing_file.txt'

#                 modified, added, removed = changes(path, ignore: %r{^ignored_directory/}, recursive: true) do
#                   touch 'ignored_directory/existing_file.txt'
#                   touch 'ignored_directory/subdirectory/existing_file.txt'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end
#       end

#       context 'when a file is moved' do
#         it 'detects the file movement' do
#           fixtures do |path|
#             touch 'move_me.txt'

#             modified, added, removed = changes(path) do
#               mv 'move_me.txt', 'new_name.txt'
#             end

#             added.should =~ %w(new_name.txt)
#             modified.should be_empty
#             removed.should =~ %w(move_me.txt)
#           end
#         end

#         context 'given an existing directory' do
#           context 'with recursive option set to true' do
#             it 'detects the file movement into the directory' do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'move_me.txt'

#                 modified, added, removed = changes(path, recursive: true) do
#                   mv 'move_me.txt', 'a_directory/move_me.txt'
#                 end

#                 added.should =~ %w(a_directory/move_me.txt)
#                 modified.should be_empty
#                 removed.should =~ %w(move_me.txt)
#               end
#             end

#             it 'detects a file movement out of the directory' do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/move_me.txt'

#                 modified, added, removed = changes(path, recursive: true) do
#                   mv 'a_directory/move_me.txt', 'i_am_here.txt'
#                 end

#                 added.should =~ %w(i_am_here.txt)
#                 modified.should be_empty
#                 removed.should =~ %w(a_directory/move_me.txt)
#               end
#             end

#             it 'detects a file movement between two directories' do
#               fixtures do |path|
#                 mkdir 'from_directory'
#                 touch 'from_directory/move_me.txt'
#                 mkdir 'to_directory'

#                 modified, added, removed = changes(path, recursive: true) do
#                   mv 'from_directory/move_me.txt', 'to_directory/move_me.txt'
#                 end

#                 added.should =~ %w(to_directory/move_me.txt)
#                 modified.should be_empty
#                 removed.should =~ %w(from_directory/move_me.txt)
#               end
#             end
#           end

#           context 'with recursive option set to false' do
#             it "doesn't detect the file movement into the directory" do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'move_me.txt'

#                 modified, added, removed = changes(path, recursive: false) do
#                   mv 'move_me.txt', 'a_directory/move_me.txt'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should =~ %w(move_me.txt)
#               end
#             end

#             it "doesn't detect a file movement out of the directory" do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/move_me.txt'

#                 modified, added, removed = changes(path, recursive: false) do
#                   mv 'a_directory/move_me.txt', 'i_am_here.txt'
#                 end

#                 added.should =~ %w(i_am_here.txt)
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end

#             it "doesn't detect a file movement between two directories" do
#               fixtures do |path|
#                 mkdir 'from_directory'
#                 touch 'from_directory/move_me.txt'
#                 mkdir 'to_directory'

#                 modified, added, removed = changes(path, recursive: false) do
#                   mv 'from_directory/move_me.txt', 'to_directory/move_me.txt'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end

#             context 'given a directory with subdirectories' do
#               it 'detects a file movement between two subdirectories' do
#                 fixtures do |path|
#                   mkdir_p 'a_directory/subdirectory'
#                   mkdir_p 'b_directory/subdirectory'
#                   touch   'a_directory/subdirectory/move_me.txt'

#                   modified, added, removed = changes(path, recursive: true) do
#                     mv 'a_directory/subdirectory/move_me.txt', 'b_directory/subdirectory'
#                   end

#                   added.should =~ %w(b_directory/subdirectory/move_me.txt)
#                   modified.should be_empty
#                   removed.should =~ %w(a_directory/subdirectory/move_me.txt)
#                 end
#               end

#               context 'with an ignored subdirectory' do
#                 it "doesn't detect the file movement between subdirectories" do
#                   fixtures do |path|
#                     mkdir_p 'a_ignored_directory/subdirectory'
#                     mkdir_p 'b_ignored_directory/subdirectory'
#                     touch   'a_ignored_directory/subdirectory/move_me.txt'

#                     modified, added, removed = changes(path, ignore: %r{^(?:a|b)_ignored_directory/}, recursive: true) do
#                       mv 'a_ignored_directory/subdirectory/move_me.txt', 'b_ignored_directory/subdirectory'
#                     end

#                     added.should be_empty
#                     modified.should be_empty
#                     removed.should be_empty
#                   end
#                 end
#               end
#             end

#             context 'with all paths passed as params' do
#               it 'detects the file movement into the directory' do
#                 fixtures do |path|
#                   mkdir 'a_directory'
#                   touch 'move_me.txt'

#                   modified, added, removed = changes(path, recursive: false, paths: [path, "#{path}/a_directory"]) do
#                     mv 'move_me.txt', 'a_directory/move_me.txt'
#                   end

#                   added.should =~ %w(a_directory/move_me.txt)
#                   modified.should be_empty
#                   removed.should =~ %w(move_me.txt)
#                 end
#               end

#               it 'detects a file moved outside of a directory' do
#                 fixtures do |path|
#                   mkdir 'a_directory'
#                   touch 'a_directory/move_me.txt'

#                   modified, added, removed = changes(path, recursive: false, paths: [path, "#{path}/a_directory"]) do
#                     mv 'a_directory/move_me.txt', 'i_am_here.txt'
#                   end

#                   added.should =~ %w(i_am_here.txt)
#                   modified.should be_empty
#                   removed.should =~ %w(a_directory/move_me.txt)
#                 end
#               end

#               it 'detects a file movement between two directories' do
#                 fixtures do |path|
#                   mkdir 'from_directory'
#                   touch 'from_directory/move_me.txt'
#                   mkdir 'to_directory'

#                   modified, added, removed = changes(path, recursive: false, paths: [path, "#{path}/from_directory", "#{path}/to_directory"]) do
#                     mv 'from_directory/move_me.txt', 'to_directory/move_me.txt'
#                   end

#                   added.should =~ %w(to_directory/move_me.txt)
#                   modified.should be_empty
#                   removed.should =~ %w(from_directory/move_me.txt)
#                 end
#               end
#             end
#           end
#         end
#       end

#       context 'when a file is deleted' do
#         it 'detects the file removal' do
#           fixtures do |path|
#             touch 'unnecessary.txt'

#             modified, added, removed = changes(path) do
#               rm 'unnecessary.txt'
#             end

#             added.should be_empty
#             modified.should be_empty
#             removed.should =~ %w(unnecessary.txt)
#           end
#         end

#         it "deletes the file from the record" do
#           fixtures do |path|
#             touch 'unnecessary.txt'

#             changes(path) do
#               @record.paths[path]['unnecessary.txt'].should_not be_nil

#               rm 'unnecessary.txt'
#             end

#             @record.paths[path]['unnecessary.txt'].should be_nil
#           end
#         end

#         it "deletes the path from the paths checksums" do
#           fixtures do |path|
#             touch 'unnecessary.txt'

#             changes(path) do
#               @record.sha1_checksums["#{path}/unnecessary.txt"] = 'foo'

#               rm 'unnecessary.txt'
#             end

#             @record.sha1_checksums["#{path}/unnecessary.txt"].should be_nil
#           end
#         end

#         context 'given an existing directory' do
#           context 'with recursive option set to true' do
#             it 'detects the file removal' do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/do_not_use.rb'

#                 modified, added, removed = changes(path, recursive: true) do
#                   rm 'a_directory/do_not_use.rb'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should =~ %w(a_directory/do_not_use.rb)
#               end
#             end
#           end

#           context 'with recursive option set to false' do
#             it "doesn't detect the file removal" do
#               fixtures do |path|
#                 mkdir 'a_directory'
#                 touch 'a_directory/do_not_use.rb'

#                 modified, added, removed = changes(path, recursive: false) do
#                   rm 'a_directory/do_not_use.rb'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end

#         context 'given a directory with subdirectories' do
#           it 'detects the file removal in subdirectories' do
#             fixtures do |path|
#               mkdir_p 'a_directory/subdirectory'
#               touch   'a_directory/subdirectory/do_not_use.rb'

#               modified, added, removed = changes(path, recursive: true) do
#                 rm 'a_directory/subdirectory/do_not_use.rb'
#               end

#               added.should be_empty
#               modified.should be_empty
#               removed.should =~ %w(a_directory/subdirectory/do_not_use.rb)
#             end
#           end

#           context 'with an ignored subdirectory' do
#             it "doesn't detect files removals in neither the directory nor its subdirectories" do
#               fixtures do |path|
#                 mkdir_p 'ignored_directory/subdirectory'
#                 touch   'ignored_directory/do_not_use.rb'
#                 touch   'ignored_directory/subdirectory/do_not_use.rb'

#                 modified, added, removed = changes(path, ignore: %r{^ignored_directory/}, recursive: true) do
#                   rm 'ignored_directory/do_not_use.rb'
#                   rm 'ignored_directory/subdirectory/do_not_use.rb'
#                 end

#                 added.should be_empty
#                 modified.should be_empty
#                 removed.should be_empty
#               end
#             end
#           end
#         end
#       end
#     end

#     context 'multiple file operations' do
#       it 'detects the added files' do
#         fixtures do |path|
#           modified, added, removed = changes(path) do
#             touch 'a_file.rb'
#             touch 'b_file.rb'
#             mkdir 'a_directory'
#             touch 'a_directory/a_file.rb'
#             touch 'a_directory/b_file.rb'
#           end

#           added.should =~ %w(a_file.rb b_file.rb a_directory/a_file.rb a_directory/b_file.rb)
#           modified.should be_empty
#           removed.should be_empty
#         end
#       end

#       it 'detects the modified files' do
#         fixtures do |path|
#           touch 'a_file.rb'
#           touch 'b_file.rb'
#           mkdir 'a_directory'
#           touch 'a_directory/a_file.rb'
#           touch 'a_directory/b_file.rb'

#           modified, added, removed = changes(path) do
#             small_time_difference
#             touch 'b_file.rb'
#             touch 'a_directory/a_file.rb'
#           end

#           added.should be_empty
#           modified.should =~ %w(b_file.rb a_directory/a_file.rb)
#           removed.should be_empty
#         end
#       end

#       it 'detects the removed files' do
#         fixtures do |path|
#           touch 'a_file.rb'
#           touch 'b_file.rb'
#           mkdir 'a_directory'
#           touch 'a_directory/a_file.rb'
#           touch 'a_directory/b_file.rb'

#           modified, added, removed = changes(path) do
#             rm 'b_file.rb'
#             rm 'a_directory/a_file.rb'
#           end

#           added.should be_empty
#           modified.should be_empty
#           removed.should =~ %w(b_file.rb a_directory/a_file.rb)
#         end
#       end
#     end

#     context 'single directory operations' do
#       it 'detects a moved directory' do
#         fixtures do |path|
#           mkdir 'a_directory'
#           mkdir 'a_directory/nested'
#           touch 'a_directory/a_file.rb'
#           touch 'a_directory/b_file.rb'
#           touch 'a_directory/nested/c_file.rb'

#           modified, added, removed = changes(path) do
#             mv 'a_directory', 'renamed'
#           end

#           added.should =~ %w(renamed/a_file.rb renamed/b_file.rb renamed/nested/c_file.rb)
#           modified.should be_empty
#           removed.should =~ %w(a_directory/a_file.rb a_directory/b_file.rb a_directory/nested/c_file.rb)
#         end
#       end

#       it 'detects a removed directory' do
#         fixtures do |path|
#           mkdir 'a_directory'
#           touch 'a_directory/a_file.rb'
#           touch 'a_directory/b_file.rb'

#           modified, added, removed = changes(path) do
#             rm_rf 'a_directory'
#           end

#           added.should be_empty
#           modified.should be_empty
#           removed.should =~ %w(a_directory/a_file.rb a_directory/b_file.rb)
#         end
#       end

#       it "deletes the directory from the record" do
#         fixtures do |path|
#           mkdir 'a_directory'
#           touch 'a_directory/file.rb'

#           changes(path) do
#             @record.paths.should have(2).paths
#             @record.paths[path]['a_directory'].should_not be_nil
#             @record.paths["#{path}/a_directory"]['file.rb'].should_not be_nil

#             rm_rf 'a_directory'
#           end

#           @record.paths.should have(1).paths
#           @record.paths[path]['a_directory'].should be_nil
#           @record.paths["#{path}/a_directory"]['file.rb'].should be_nil
#         end
#       end

#       context 'with nested paths' do
#         it 'detects removals without crashing - #18' do
#           fixtures do |path|
#             mkdir_p 'a_directory/subdirectory'
#             touch   'a_directory/subdirectory/do_not_use.rb'

#             modified, added, removed = changes(path) do
#               rm_r 'a_directory'
#             end

#             added.should be_empty
#             modified.should be_empty
#             removed.should =~ %w(a_directory/subdirectory/do_not_use.rb)
#           end
#         end
#       end
#     end

#     context 'with a path outside the directory for which a record is made' do
#       it "skips that path and doesn't check for changes" do
#           fixtures do |path|
#             modified, added, removed = changes(path, paths: ['some/where/outside']) do
#               @record.should_not_receive(:detect_additions)
#               @record.should_not_receive(:detect_modifications_and_removals)

#               touch 'new_file.rb'
#             end

#             added.should be_empty
#             modified.should be_empty
#             removed.should be_empty
#           end
#       end
#     end

#     context 'with the relative_paths option set to false' do
#       it 'returns full paths in the changes hash' do
#         fixtures do |path|
#           touch 'a_file.rb'
#           touch 'b_file.rb'

#           modified, added, removed = changes(path, relative_paths: false) do
#             small_time_difference
#             rm    'a_file.rb'
#             touch 'b_file.rb'
#             touch 'c_file.rb'
#             mkdir 'a_directory'
#             touch 'a_directory/a_file.rb'
#           end

#           added.should =~ ["#{path}/c_file.rb", "#{path}/a_directory/a_file.rb"]
#           modified.should =~ ["#{path}/b_file.rb"]
#           removed.should =~ ["#{path}/a_file.rb"]
#         end
#       end
#     end

#     context 'within a directory containing unreadble paths - #32' do
#       it 'detects changes more than a second apart' do
#         fixtures do |path|
#           touch 'unreadable_file.txt'
#           chmod 000, 'unreadable_file.txt'

#           modified, added, removed = changes(path) do
#             small_time_difference
#             touch 'unreadable_file.txt'
#           end

#           added.should be_empty
#           modified.should =~ %w(unreadable_file.txt)
#           removed.should be_empty
#         end
#       end

#       context 'with multiple changes within the same second' do
#         before { ensure_same_second }

#         it 'does not detect changes even if content changes', unless: described_class::HIGH_PRECISION_SUPPORTED do
#           fixtures do |path|
#             touch 'unreadable_file.txt'

#             modified, added, removed = changes(path) do
#               open('unreadable_file.txt', 'w') { |f| f.write('foo') }
#               chmod 000, 'unreadable_file.txt'
#             end

#             added.should be_empty
#             modified.should be_empty
#             removed.should be_empty
#           end
#         end
#       end
#     end

#     context 'within a directory containing a removed file - #39' do
#       it 'does not raise an exception when hashing a removed file' do

#         # simulate a race condition where the file is removed after the
#         # change event is tracked, but before the hash is calculated
#         Digest::SHA1.should_receive(:file).twice.and_raise(Errno::ENOENT)

#         fixtures do |path|
#           lambda {
#             touch 'removed_file.txt'
#             changes(path) { touch 'removed_file.txt' }
#           }.should_not raise_error(Errno::ENOENT)
#         end
#       end
#     end

#     context 'within a directory containing a unix domain socket file' do
#       it 'does not raise an exception when hashing a unix domain socket file' do
#         fixtures do |path|
#           require 'socket'
#           UNIXServer.new('unix_domain_socket.sock')
#           lambda { changes(path){} }.should_not raise_error(Errno::ENXIO)
#         end
#       end
#     end

#     context 'with symlinks', unless: windows? do
#       it 'looks at symlinks not their targets' do
#         fixtures do |path|
#           touch 'target'
#           symlink 'target', 'symlink'

#           record = described_class.new(path)
#           record.build

#           sleep 1
#           touch 'target'

#           record.fetch_changes([path], relative_paths: true)[:modified].should == ['target']
#         end
#       end

#       it 'handles broken symlinks' do
#         fixtures do |path|
#           symlink 'target', 'symlink'

#           record = described_class.new(path)
#           record.build

#           sleep 1
#           rm 'symlink'
#           symlink 'new-target', 'symlink'
#           record.fetch_changes([path], relative_paths: true)
#         end
#       end
#     end
#   end
# end
