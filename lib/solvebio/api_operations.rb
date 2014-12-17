module SolveBio
    module APIOperations
        module Create
            module ClassMethods
                def create(params={})
                    response = Client.post(url, params)
                    Util.to_solve_object(response)
                end
            end

            def self.included(base)
                base.extend(ClassMethods)
            end
        end

        module Delete
            def delete(params={})
                response = Client.request('delete', url, params)
                refresh_from(response)
            end
        end
        
        module Update
            def save
                refresh_from(request('patch', url,
                                     {:payload => serialize(self)}))
                return self
            end

            def serialize(obj)
                params = {}
                if obj.unsaved_values
                    obj.unsaved_values.each do |k|
                        next if k == 'id'
                        params[k] = getattr(obj, k) or ''
                    end
                end
                params
            end
        end
        
        module Download
            def download(path=nil)
                download_url = url + '/download'
                response = Client.get(download_url, :raw => true)

                if response.code != 302
                    # Some kind of error. We expect a redirect
                    raise SolveError('Could not download file: response code' %
                                     response.status_code)
                end

                download_url = response.headers[:location]
                filename = download_url.split('%3B%20filename%3D')[1]

                path = Dir.tmpdir unless path
                filename = File.join(path, filename)
                response = Client.get(download_url, :raw => true, :auth => false, :default_headers => false)

                File.open(filename, 'wb') do |fh|
                    fh.write(response.body)
                end

                self['filename'] = filename
                self['code'] = response.code
                self
            end
        end
        
        module Help
            attr_reader :have_launchy

            @@have_launchy = false
            begin
                @@have_launchy = require 'launchy'
            rescue LoadError
            end

            def self.included base
                base.send :include, InstanceMethods
            end

            module InstanceMethods
                def help
                    open_help(self['full_name'])
                end
            end

            def open_help(path)
                url = URI::join('https://www.solvebio.com/', path)
                if @@have_launchy
                    Launchy.open(url)
                else
                    puts('The SolveBio Ruby client needs the "launchy" gem to ' +
                         "open help url: #{url.to_s}")
                end
            end
        end
        
        module List
            module ClassMethods
                def all(params={})
                    response = Client.get(url, {:params => params})
                    Util.to_solve_object(response)
                end
            end

            def self.included base
                base.extend ClassMethods
            end
        end
        
        module Search
            module ClassMethods
                def search(query='', params={})
                    params['q'] = query
                    response = Client.get(url, {:params => params})
                    Util.to_solve_object(response)
                end
            end

            def self.included base
                base.extend ClassMethods
            end
        end
    end
end
