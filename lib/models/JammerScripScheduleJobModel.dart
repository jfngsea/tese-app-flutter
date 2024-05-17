class JammerScriptScheduleJob {
  String jobid;
  String jobname;
  DateTime jobdate;

  JammerScriptScheduleJob(this.jobid, this.jobname, this.jobdate);

  factory JammerScriptScheduleJob.fromJSON(Map<String, dynamic> json) {
    return JammerScriptScheduleJob(
      json["jobid"] as String,
      json["jobname"] as String,
      DateTime.parse(json["jobdate"])

    );
  }

}