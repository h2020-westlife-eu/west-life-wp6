﻿using System;
using System.Collections.Generic;
using System.Linq;

namespace MetadataService.Services.Files
{
    public static class ProviderFactory
    {
        public static Dictionary<string, IProviderCreator> AvailableProviders;

        static ProviderFactory()
        {
            //get all implementation of IProviderCreator
            var type = typeof(IProviderCreator);
            var types = AppDomain.CurrentDomain.GetAssemblies()
                .SelectMany(s => s.GetTypes())
                .Where(p => type.IsAssignableFrom(p));
            //initialize provider creators - factory method
            AvailableProviders = new Dictionary<string, IProviderCreator>(types.Count());
            //register each instance of provider creator - factory method
            foreach (var creatortype in types)
            {
                if (creatortype.IsClass)
                {
                    //e.g. gets the type name from class name, e.g. 'Dropbox' from name 'DropboxProviderCreator'
                    var typename = creatortype.Name.Substring(0, creatortype.Name.IndexOf("Provider"));
                    var obj = (IProviderCreator) Activator.CreateInstance(creatortype);
                    AvailableProviders.Add(typename, obj);
                }
            }
        }


        public static void RegisterAvailableProvider(string type, IProviderCreator impl)
        {
            AvailableProviders.Add(type, impl);
        }
    }
}