### Memory usage in lib jobs

Some lib jobs work with large data files, or many data files.  In these scenarios, you may need to consider how much memory you are allocating and retaining throughout the job run to make sure that you don't cause the server to run out of memory.

#### General guidelines

* If there is any chance that a file will be large, or that there will be many of them, don't slurp the entire file into a memory as a string (e.g. with File.read)
* If you need to temporarily store some data during a process, consider using a Tempfile object, rather than storing it in memory
* When handling a very large CSV, you should use the `CSV.foreach` method, rather than `CSV.read` or `CSV.parse` (see [Common issues with CSV parsing and solutions to them](https://www.paweldabrowski.com/articles/ruby-csv-common-issues))

#### Identifying if a job runs out of memory

* Open a tmux session on staging (`tmux new -s my-job-session`)
* Run the job with a production-level volume of data
* While it is running, you may also want to run `watch free -h` to get regular updates on how much memory the job is consuming.
* If the job ends suddenly, and the screen says "Killed", your job probably took all the memory on the server and the OS needed to stop it.

#### Troubleshooting steps with the memory profiler

* Decide on a representative set of data to process.  Memory profiling itself takes a lot of memory, so if you try doing it with production levels of data, it will probably never finish.
* Add the memory_profiler gem to your bundle
* Wrap your job in a MemoryProfiler block, e.g.
    ```
    report = MemoryProfiler.report do
      job = AlmaSubmitCollection::AlmaSubmitCollectionJob.new
      job.run
    end
    puts report.pretty_print
    ```
* Run the job locally
* Look for these key areas of the report:
  * allocated memory by location
  * retained memory by location
  * string reports
  * anything you find surprising (e.g. if the JSON gem is allocating a lot of memory, but you don't process any JSON in your job)
* When you find a bottleneck in the "allocated memory by location" section of the report:
  * This part of the report includes a line number.  Check out the code on that line, and see if you need to allocate it in the first place.
  * If there isn't an immediately obvious issue on that line, try running your job again without the memory profiler, but with a byebug or other debugger.  In a debugger, you can check:
    * What arguments are in play
	* How many times is this code called (i.e. is it called once during the job, or does it allocate many new objects during the job run?)
	* What is the stacktrace? (with `puts Thread.current.backtrace.join("\n")`)
	* How much memory does a particular object take (with `require 'objspace'` and `ObjectSpace.memsize_of(my_object)`)?
