﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using MetadataService.Services.Settings;
using ServiceStack.DataAnnotations;
using ServiceStack.ServiceHost;
using ServiceStack.ServiceInterface;
using ServiceStack.ServiceInterface.Cors;

namespace MetadataService.Services.Files
{
    using ProviderList = List<ProviderItem>;

    /*    [Route("/files/{Provider}/{Path*}")]
    /files -- returns all available providers
    /files/dropbox -- returns files in root dir of dropbox
    /files/dropbox/Documents -- ...
    /files/dropbox/ -- sets dropbox configuration
    /files/dropbox/connection
  */
    [Route("/files", "GET,HEAD,PUT,OPTIONS")]
    [Route("/files/{alias}", "DELETE")]
    public class ProviderItem : IReturn<ProviderList>
    {
        [AutoIncrement]
        public int Id { get; set; }

        public string alias { get; set; } //(optional - if not set - it is generated
        //alias used to distinguish between multiple providers per user /files/{alias}/{path}

        public string type { get; set; } //(mandatory) type of provider to distinguish available implementation
        public string securetoken { get; set; } //(mandatory), accesstoken or password used to transfer tokens to store
        public string username { get; set; } //(mandatory for some types e.g. webdav,b2drop)
        public string output { get; set; } //output property debug output from scripts
        public string loggeduser { get; set; } //internal field, filled by service

        [IgnoreDataMember]
        [Ignore]
        public string loggeduserhash { get; set; } //internal field, filled by service, not stored in DB
        public string accessurl { get; set; } //(mandatory for type webdav), not used by other providers
    }

    [Route("/files/{Providerpath}/{Path*}", "GET,HEAD,OPTIONS")]
    public class GetFiles //: IReturn<List<SBFile>>
    {
        public string Providerpath { get; set; }
        public string Path { get; set; }
    }

    [Route("/providers", "GET")]
    public class GetProviders : IReturn<List<string>>
    {
        public string name { get; set; }
        public string username { get; set; }
    }

    public class DjangoUserInfo
    {
        public string username { get; set; }
        public string email { get; set; }
    }

    public class DjangoAuthproxyInfo
    {
        public string signed_url { get; set; }
    }

    [EnableCors(allowCredentials:true)]
    [VreCookieRequestFilter]
    public class ProviderService : GenericProviderMethods
    {
        
        //private static Dictionary<string,IProviderCreator> AvailableProviders; //provider name and factory method
        //   private Dictionary<string, UserProvider> UserProviders = new Dictionary<string, UserProvider>();

        /** returns list of configured file providers */
        public ProviderList Get(ProviderItem request)
        {
            return getUserProviderItems();
        }

        public void Options(ProviderItem request)
        {            
        }

        /** returns list of available providers, which can be configured by the user */
        public List<string> Get(GetProviders request)
        {
            return ProviderFactory.AvailableProviders.Keys.ToList();
        }

        //registers new alias and provider which serve it
        public ProviderList Put(ProviderItem request)
        {
            getUserProviders().Add(request, storage, Db);
            return getUserProviderItems();
        }
        
        public void Options(GetProviders request) {}

        //deregister the alias and provider which serve it
        public ProviderList Delete(ProviderItem request)
        {
            return getUserProviders().Delete(request);
        }


        public object Get(GetFiles request)
        {
            //delegate to provider
            return getUserProviders().GetFileList(request,base.Request);
        }

        public void Options(GetFiles request){ }

        public void Head(GetFiles request)
        {
            //delegate to provider
            try
            {
                getUserProviders().GetFileList(request,base.Request);
                Response.StatusCode = 200;
            }
            catch (Exception e)
            {
                Console.WriteLine("Error: HEAD to resource:{0}\nmessage:{1}\nstacktrace:{2}",
                    request.Providerpath + "/" + request.Path, e.Message, e.StackTrace);
                Response.StatusDescription = e.Message;
                Response.StatusCode = 404;
            }
        }
    }
}