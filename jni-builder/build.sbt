lazy val commonSettings = Seq(
  organization := "be.botkop",
  isSnapshot := true,
  version := "0.1-SNAPSHOT",
  
  crossPaths := false,  // pure Java library
  autoScalaLibrary := false, // pure Java library

  publishMavenStyle := true
)

lazy val torch = (project in file("java")).settings(commonSettings: _*).settings(
  name := "torch-cpu"
)

