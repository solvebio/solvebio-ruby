module SolveBio
    class Sample < APIResource
        #  Samples are VCF files uploaded to the SolveBio API. We currently
        #  support uncompressed, extension `.vcf`, and gzip-compressed, extension
        #   `.vcf.gz`, VCF files. Any other extension will be rejected.
        include SolveBio::APIOperations::List
        include SolveBio::APIOperations::Delete
        include SolveBio::APIOperations::Download
        include SolveBio::APIOperations::Help

        def annotate
            Annotation.create :sample_id => self.id
        end

        def self.create(genome_build, params={})
            if params.member?(:vcf_url)
                if params.member?(:vcf_file)
                    raise TypeError,
                    'Specified both vcf_url and vcf_file; use only one'
                end
                
                self.create_from_url(genome_build, params[:vcf_url])
            elsif params.member?(:vcf_file)
                return self.create_from_file(genome_build, params[:vcf_file])
            else
                raise TypeError,
                'Must specify exactly one of vcf_url or vcf_file parameter'
            end
        end

        # Creates from the specified file.  The data of the should be in
        # VCF format.
        def self.create_from_file(genome_build, vcf_file)
            data = {
                :genome_build  => genome_build,
                :vcf_file => File.open(vcf_file, 'rb')
            }
            response = Client.post(url, data, :json => false)
            Util.to_solve_object(response)
        end

        # Creates from the specified URL.  The data of the should be in
        # VCF format.
        def self.create_from_url(genome_build, vcf_url)
            params = {:genome_build  => genome_build,
                      :vcf_url       => vcf_url}
            begin
                response = Client.post(url, params)
            rescue SolveError => response
            end
            Util.to_solve_object(response)
        end
    end
end
