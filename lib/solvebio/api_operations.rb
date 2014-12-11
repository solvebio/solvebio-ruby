module SolveBio
  module APIOperations
    module Create
      module ClassMethods
        def create(params={})
            url = SolveBio::APIResource.class_url(self)
            response = SolveBio::Client.client
                .request('post', url, {:payload => params} )
            to_solve_object(response)
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    module Delete
        def delete(params={})
            begin
                self.refresh_from(SolveBio::Client.client
                                     .request('delete', instance_url,
                                              {:payload => params}))
            rescue SolveError => response
                response.to_solve_object(cls)
            end
        end
    end
    
    module Update
        def save
            refresh_from(request('patch', instance_url(),
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
            download_url = instance_url + '/download'
            response = SolveBio::Client.client.get(download_url, :raw => true)

            if response.code != 302
                # Some kind of error. We expect a redirect
                raise SolveError('Could not download file: response code' %
                                 response.status_code)
            end

            download_url = response.headers[:location]
            filename = download_url.split('%3B%20filename%3D')[1]

            path = Dir.tmpdir unless path
            filename = File.join(path, filename)
            response = nil

            response = SolveBio::Client.client.get(download_url, :raw => true,
                                                   :default_headers => false)

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
                url = SolveBio::APIResource.class_url(self)
                response = SolveBio::Client.client
                    .request('get', url, {:params => params})
                return response.to_solvebio(self)
            end
        end

        def self.included base
            base.extend ClassMethods
        end

        def to_s
            if self.class.constants.member?(:TAB_FIELDS)
                items = self.class.const_get(:TAB_FIELDS).map{
                    |name| [name, self[name]]
                }
            else
                items = self
            end
            return SolveBio::Tabulate.tabulate(items, ['Fields', 'Data'],
                                               ['right', 'left'], true)
        end

        def size
            self[:total]
        end
        alias :total :size
    end
    
    module Search
        def self.included base
            base.extend ClassMethods
        end

        module ClassMethods
            def search(query='', params={})
                params['q'] = query
                url = SolveBio::APIResource.class_url(self)
                response = SolveBio::Client.client
                    .request('get', url, {:params => params})
                response.to_solvebio
            end
        end
    end
  end
end
