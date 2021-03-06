/**
 * Created by Tomas Kulhanek on 2/17/17.
 */

import * as CodeMirror from "codemirror";
import "codemirror/mode/clike/clike";
import "codemirror/mode/htmlmixed/htmlmixed";
import "codemirror/mode/javascript/javascript";

import {EventAggregator} from 'aurelia-event-aggregator';
import {HttpClient} from 'aurelia-fetch-client';
import {EditFile} from '../filepicker/messages';
import {bindable} from 'aurelia-framework';
import {Vfstorage} from './vfstorage';

//import $ from 'jquery';

export class Fileeditor {
  static inject = [Element,EventAggregator, HttpClient];
  @bindable pid;

  constructor(el,ea) {
    this.el = el;
    this.ea = ea;
    this.client = new HttpClient();
    this.client.configure(config => {
      config
        .rejectErrorResponses()
        .withBaseUrl('')
        .withDefaults({
          credentials: 'same-origin'
        })
    });
    this.isimage=false;
    this.filename="";
  }

  attached() {
    this.subscription = this.ea.subscribe(EditFile, msg => this.selectFile(msg.file,msg.senderid));
    let editor = this.el.querySelector(".Codemirror");
    //prevent blured render if not shown before
    //if (editor==null)
    this.codemirror = CodeMirror.fromTextArea(this.cmTextarea, {
      lineNumbers: true,
      mode: "text/x-less",
      lineWrapping: true
    });
    this.codemirror.refresh();
  }
  
  detached(){
    this.subscription.dispose();
  }

  selectFile(file,senderid) {
    this.disablenextbuttons=false;
    this.offset = 0;
    let that =this;
    if (senderid!=this.pid) {
      this.imageurl = file.webdavuri;
      //visualizeimg is set & image extension is detected
      //console.log("fileeditor.selectfile() visualizeimg: isimage:")
      //console.log(localStorage.getItem("visualizeimg"));
      //vfstorage returns string - should convert to boolean
      this.isimage = (Vfstorage.getValue("visualizeimg") == "true") &&
      ((file.name.endsWith('.JPG'))||
      (file.name.endsWith('.jpg'))||
      (file.name.endsWith('.PNG'))||
      (file.name.endsWith('.png'))||
      (file.name.endsWith('.GIF'))||
      (file.name.endsWith('.gif'))||
      (file.name.endsWith('.BMP'))||
      (file.name.endsWith('.bmp'))||
      (file.name.endsWith('.SVG'))||
      (file.name.endsWith('.svg')));

      //console.log("fileeditor.selectfile() visualizeimg: isimage:")
      //console.log(this.isimage);
      if (!this.isimage)
        //fetch first 4 kb
        this.client.fetch(file.webdavuri, {credentials: 'same-origin',headers:{'Range':'bytes='+this.offset+'-'+(this.offset+4095)}})
          .then(response => response.text())
          .then(data =>{
            //console.log("fileeditor.selectfile() loading:" + file.webdavuri);
            //console.log(data);
            that.codemirror.setValue(data);
            that.codemirror.refresh();
            that.filename=file.webdavuri;
          }
        ).catch(error => {
          if (error.name ==="TypeError") {
            //fetch for range header failed, so try to get full file
            console.log('fetch on range rejected, trying without range');
            this.client.fetch(file.webdavuri, {credentials: 'same-origin'})
              .then(response => response.text())
              .then(data => {
                //console.log("fileeditor.selectfile() loading:" + file.webdavuri);
                //console.log(data);
                that.codemirror.setValue(data);
                that.codemirror.refresh();
                that.filename = file.webdavuri;
              });
          }
          else {
            alert('Error retrieving content from ' + file.webdavuri);
            console.log('Error:',error);
          }
        });
    }
  }
  
  fetchNext() {
    this.offset+=4096;
    this.client.fetch(this.filename, {credentials: 'same-origin',headers:{'Range':'bytes='+this.offset+'-'+(this.offset+4095)}})
      .then(response => response.text())
      .then(data =>{
          //console.log("fileeditor.selectfile() loading:" + this.file.webdavuri);
          //console.log(data);
          this.codemirror.replaceRange(data, CodeMirror.Pos(this.codemirror.lastLine()));
          //this.codemirror.setValue(data);
          this.codemirror.refresh();
        }
      ).catch(error => {
        if (error.status === 416) {
          //reached end of file
          this.disablenextbuttons=true;
        } else {
          alert('Error retrieving content from ' + this.filename);
          console.log(error);
        }
    });
  }
  
  fetchRest() {
    this.client.fetch(this.file.webdavuri, {credentials: 'same-origin'})
      .then(response => response.text())
      .then(data =>{
          //console.log("fileeditor.selectfile() loading:" + this.filename);
          //console.log(data);
          that.codemirror.setValue(data);
          that.codemirror.refresh();
        }
      ).catch(error => {
      alert('Error retrieving content from ' + this.filename);
      console.log(error);
    });
    
  }
}
