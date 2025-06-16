If the job has failed for a while, you will need to run the days on which it failed to catch up any
missing people.  For example, if the job has failed consistently since May 20, 2025 and today is
June 13, 2025, run:

```
cd /opt/lib-jobs/current
AlmaPeople::AlmaPersonFeed.new(begin_date: "2025-05-20", end_date: "2025-06-13").run
```

Alma will then pick them up at 1am Princeton Time.
