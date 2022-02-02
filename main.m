/*
   Project: buildtool

   Author: Gregory John Casamento,,,

   Created: 2011-08-20 11:42:51 -0400 by heron
*/

#import <Foundation/Foundation.h>
#import <XCode/PBXCoder.h>
#import <XCode/PBXContainer.h>
#import <XCode/NSString+PBXAdditions.h>
#import <XCode/XCWorkspaceParser.h>
#import <XCode/XCWorkspace.h>

NSString *
findProjectFilename(NSArray *projectDirEntries)
{
  NSEnumerator *e = [projectDirEntries objectEnumerator];
  NSString     *fileName;

  while ((fileName = [e nextObject]))
    {
      NSRange range = [fileName rangeOfString:@"._"];
      if ([[fileName pathExtension] isEqual: @"xcodeproj"] && range.location == NSNotFound)
	{
	  return [fileName stringByAppendingPathComponent: @"project.pbxproj"];
	}
    }

  return nil;
}

NSString *
findWorkspaceFilename(NSArray *projectDirEntries)
{
  NSEnumerator *e = [projectDirEntries objectEnumerator];
  NSString     *fileName;

  while ((fileName = [e nextObject]))
    {
      NSRange range = [fileName rangeOfString:@"._"];
      if ([[fileName pathExtension] isEqual: @"xcworkspace"] && range.location == NSNotFound)
	{
	  return [fileName stringByAppendingPathComponent: @"contents.xcworkspacedata"];
	}
    }

  return nil;
}

int
main(int argc, const char *argv[])
{
  if(argc == 0)
    {
      return 0;
    }

  setlocale(LC_ALL, "en_US.utf8");
  id pool = [[NSAutoreleasePool alloc] init];
  NSString                   *fileName = nil;
  NSString                   *function = nil; 
  PBXCoder                   *coder = nil;
  PBXContainer               *container = nil;
  NSString                   *projectDir;
  NSArray                    *projectDirEntries;
  NSFileManager              *fileManager = [NSFileManager defaultManager];
  BOOL                        isProject = NO;
  const char *arg = NULL;
  
  projectDir        = [fileManager currentDirectoryPath];
  projectDirEntries = [fileManager directoryContentsAtPath: projectDir];

  if (argc > 1)
    {
      arg = argv[1];
    }
  else
    {
      arg = "build";
    }

  // Get the project...
  if(arg != NULL)
    {
      NSString *argument = [NSString stringWithCString: arg];

      if ([argument isEqualToString: @"build"] ||
          [argument isEqualToString: @"install"] ||
          [argument isEqualToString: @"clean"])
        {
          function = argument;
          fileName = findWorkspaceFilename(projectDirEntries);
          if (fileName != nil)
            {
              isProject = NO;
            }
          else
            {
              isProject = YES;
              fileName = findProjectFilename(projectDirEntries);
            }
        }
      else
        {
          fileName = [argument stringByAppendingPathComponent: 
                                 @"project.pbxproj"];
          if([[argument pathExtension] isEqualToString:@"xcodeproj"] == NO)
            {
              fileName = findProjectFilename(projectDirEntries);
              function = [NSString stringWithCString: argv[1]];
              isProject = YES;
            }
          else  if([[argument pathExtension] isEqualToString:@"xcworkspace"] == NO)
            {
              fileName = findWorkspaceFilename(projectDirEntries);
              function = [NSString stringWithCString: argv[1]];
              isProject = NO;
            }
          
	  // If there is a project, add the build operation...
	  if(argv[2] != NULL && argc > 1)
	    {
	      function = [NSString stringWithCString: argv[2]];
	    }
        }
    }

  if([function isEqualToString: @""] || function == nil)
    {
      function = @"build"; // default action...
    }

  NS_DURING
    {
      NSString *display = [function stringByCapitalizingFirstCharacter];
      SEL operation = NSSelectorFromString(function);
      
      if (isProject)
	{
	  // Unarchive...
	  coder = [[PBXCoder alloc] initWithContentsOfFile: fileName];
	  container = [coder unarchive];
	  
	  // Build...
	  if ([container respondsToSelector: operation])
	    {        
	      // build...
	      puts([[NSString stringWithFormat: @"\033[1;32m**\033[0m Start operation %@", display] cString]); 
	      if ([container performSelector: operation])
		{
		  puts([[NSString stringWithFormat: @"\033[1;32m**\033[0m %@ Succeeded", display] cString]);
		}
	      else
		{
		  puts([[NSString stringWithFormat: @"\033[1;31m**\033[0m %@ Failed", display] cString]);
		}
	    }
	  else
	    {
	      puts([[NSString stringWithFormat: @"Unknown build operation \"%@",display] cString]);
	    }
	}
      else
	{
	  XCWorkspaceParser *p = [XCWorkspaceParser parseWorkspaceFile: fileName];
	  XCWorkspace *w = [p workspace];
	  
	  if ([w respondsToSelector: operation])
	    {
	      [w performSelector: operation];
	    }
	}
    }
  NS_HANDLER
    {
      NSLog(@"%@", localException);
    }
  NS_ENDHANDLER;
  
  // The end...
  [pool release];

  return 0;
}

