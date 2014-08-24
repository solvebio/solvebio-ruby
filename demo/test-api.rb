#!/usr/bin/env ruby
# Test SolveBio API
require_relative  '../lib/solvebio'

DEPOSITORY         = 'ClinVar'
DEPOSITORY_VERSION = "#{DEPOSITORY}/2.0.0-1"
DATASET            = "#{DEPOSITORY_VERSION}/Variants"

# Custom Exception class for running basic tests
class TestFail < RuntimeError
end

DEBUG = ARGV.size > 1

# Function for running small tests with nice printing and checks
def run_and_verify(func, title='run a test', check_func_symbols)
    puts "Trying to #{title}..."
    response = func.call
    check_func_symbols.each do |sym|
        unless response.send(sym)
            raise TestFail, "Failed on #{DATASET} using #{sym}"
        end
    end
    puts "\x1b[32mOK!\x1b[39m\n"
    return response
end

creds = SolveBio::Credentials.get_credentials
unless creds
    puts 'You must be logged in as a SolveBio user ' +
        'in order to run the test suite!'
    exit(1)
end

SolveBio::Client.client.api_key = creds[1]

begin
    # depository things
    load_depo = proc { SolveBio::DepositoryVersion.
        retrieve(DEPOSITORY_VERSION) }
    begin
        dataset = run_and_verify(load_depo, 'load a depository version',
                                 [:id, :str, :inspect, :instance_url])
    rescue SolveBio::Error => exc
        raise TestFail, "Loading #{DEPOSITORY_VERSION} failed! (#{exc})"
    end

    # depository things
    load_depo = proc { SolveBio::Depository.retrieve(DEPOSITORY) }
    begin
        dataset = run_and_verify(load_depo, 'load a depository',
                                 [:str, :versions, :versions_url,
                                 :first, :max, :min])
    rescue SolveBio::Error => exc
        raise TestFail, "Loading #{DEPOSITORY} failed! (#{exc})"
    end

    # try loading a dataset
    load_dataset = proc { SolveBio::Dataset.retrieve(DATASET) }
    begin
        dataset = run_and_verify(load_dataset, 'load a dataset',
                                 [:depository, :depository_version, :fields])
    rescue SolveBio::Error => exc
        raise TestFail, "Loading #{DATASET} failed! (#{exc})"
    end

    # # run a basic query
    # query = run_and_verify(dataset.query, 'run a basic query')

    # # run a basic filter
    # basic_filter = proc { query.filter(clinical_significance='Pathogenic') }
    # run_and_verify(basic_filter, 'run a basic filter')

    # # run a range filter
    # range_filter = solvebio.RangeFilter(build="hg19",
    #                                     chromosome=1,
    #                                     start=100000,
    #                                     last=900000)
    # run_and_verify(proc { query.filter(range_filter) },
    #                'run a range filter')

rescue TestFail, exc
    puts "\n\n\x1b[31mFAIL!\x1b[39m #{exc}"
end
