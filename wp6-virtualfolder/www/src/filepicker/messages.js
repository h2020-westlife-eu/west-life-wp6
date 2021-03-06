/**
 * Created by Tomas Kulhanek on 1/9/17.
 */

export class SelectedFile {
  constructor(file,senderid,linkheader){
    this.file = file;
    this.senderid = senderid;
    this.linkheader = linkheader
    console.log("SelectedFile(), linkheader:",this.linkheader);
  }
}

export class SelectedMetadata {
  constructor(file,senderid){
    this.file = file;
    this.senderid = senderid;
  }
}

export class CheckedFile {
  constructor(file,senderid){
    this.file = file;
    this.senderid = senderid;
  }
}

export class VisualizeFile {
  constructor(file,senderid){
    this.file = file;
    this.senderid = senderid;
  }
}

export class EditFile {
  constructor(file,senderid){
    this.file = file;
    this.senderid = senderid;
  }
}

export class DatasetFile {
  constructor(file,senderid){
    this.file = file;
    this.senderid = senderid;
  }
}

export class PopulateResources {
  constructor(resources,senderid){
    this.resources = resources;
    this.senderid=senderid;
  }
}
