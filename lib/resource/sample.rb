# Solvebio API Resource for Samples
require_relative 'apiresource'
require_relative 'solveobject'
require_relative '../errors'

#  Samples are VCF files uploaded to the SolveBio API. We currently
#  support uncompressed, extension `.vcf`, and gzip-compressed, extension
#   `.vcf.gz`, VCF files. Any other extension will be rejected.
class SolveBio::Sample < SolveBio::APIResource

    include SolveBio::DeletableAPIResource
    include SolveBio::DownloadableAPIResource
    include SolveBio::ListableAPIResource
    include SolveBio::HelpableAPIResource

    def annotate
        SolveBio::Annotation.create :sample_id => self.id
    end

    # FIXME: Rubyize APIResource.retrieve
    def self.retrieve(id, params={})
        SolveBio::APIResource.retrieve(self, id)
    end

    def self.create(genome_build, params={})
        if params.member?(:vcf_url)
            if params.member?(:vcf_file)
                raise TypeError,
                'Specified both vcf_url and vcf_file; use only one'
            end
            self.create_from_url(genome_build, params[:vcf_url])
        elsif params.member?(:vcf_file)
            return create_from_file(genome_build, params[:vcf_file])
        else
            raise TypeError,
            'Must specify exactly one of vcf_url or vcf_file parameter'
        end
    end

    # Creates from the specified file.  The data of the should be in
    # VCF format.
    def self.create_from_file(genome_build, vcf_file)

        fh = File.open(vcf_file, 'rb')
        params = {:genome_build  => genome_build}
        response = SolveBio::Client.client.post(class_url(self), params,
                                                :vcf_file => fh)
        to_solve_object(response)
    end

    # Creates from the specified URL.  The data of the should be in
    # VCF format.
    def self.create_from_url(genome_build, vcf_url)

        params = {:genome_build  => genome_build,
                  :vcf_url       => vcf_url}
        begin
            response = SolveBio::Client.client.post class_url(self), params
        rescue SolveBio::Error => response
        end
        to_solve_object(response)
    end
end

if __FILE__ == $0
    unless SolveBio::API_HOST == 'https://api.solvebio.com'
        SolveBio::SolveObject::CONVERSION = {
            'Sample' => SolveBio::Sample,
        } unless defined? SolveBio::SolveObject::CONVERSION
        url = 'http://downloads.solvebio.com/vcf/small_sample.vcf.gz'
        response = SolveBio::Sample.create_from_url 'hg19', url
        puts response
    end
end
