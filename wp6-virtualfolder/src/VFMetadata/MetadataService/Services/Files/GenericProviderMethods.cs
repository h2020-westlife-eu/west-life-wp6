﻿using System;
using System.Collections.Generic;
using MetadataService.Services.Settings;
using ServiceStack.ServiceInterface;

namespace MetadataService.Services.Files
{
    public class GenericProviderMethods : Service
    {
        //configures the storage
        public GenericProviderMethods()
        {
            storage = SettingsStorageInDB.GetInstance();
            //storage = SettingsStorageInFile.GetInstance();
        }
        
        protected readonly ISettingsStorage storage = SettingsStorageInDB.GetInstance();
        
        //TODO share code from ProviderService - inheritance/composition
        /*gets providers associated to the user, initialize object when needed */
        protected List<ProviderItem> getUserProviderItems()
        {
            return getUserProviders().getProviderItems();
        }

        /** determining which configured provider belongs to the user logged within this request */
        protected UserProvider getUserProviders()
        {
            try
            {
                var userid = (string) Request.Items["userid"];
                //var useremail = (string) Request.Items["email"];
                //var userauthproxy = (string) Request.Items["authproxy"];
                if (userid.Length == 0) throw new UnauthorizedAccessException();
                return UserProvider.GetInstance(userid, storage, Db);
            }
            catch (KeyNotFoundException)
            {
                throw new UnauthorizedAccessException();
            }
        }
        
        protected List<ProviderItem> getOldUserProviderItems()
        {
            return getOldUserProviders().getProviderItems();
        }

        protected List<ProviderItem> getFullOldUserProviderItems()
        {
            return getOldUserProviders().getFullProviderItems();
        }
        
        /** determining which configured provider belongs to the user logged within this request */
        protected UserProvider getOldUserProviders()
        {
            try
            {
                //var userid = (string) Request.Items["userid"];
                var useremail = (string) Request.Items["email"];
                //var userauthproxy = (string) Request.Items["authproxy"];
                if (useremail.Length == 0) throw new UnauthorizedAccessException();
                return UserProvider.GetInstance(useremail, storage, Db);
            }
            catch (KeyNotFoundException)
            {
                throw new UnauthorizedAccessException();
            }
        } 
    }
}