module SolveBio
    # Shell help
    def help
        puts <<-HELP
Constants SAMPLE_DEPO, SAMPLE_DEPO_VERSION, and SAMPLE_DATASET are
available for and example depository, depository_versions or dataset.

By setting environment variable SOLVEBIO_IRBRC, you can add your own
custom irb profile.
HELP
    end
    module_function :help
end
