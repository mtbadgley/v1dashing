# V1Dashing - an Agile Team's Dashboard

![V1Dashing](https://raw.github.com/mtbadgley/v1dashing/master/doc/images/fulldashboard_sm.png)

## Overview

As a coach, a member of a team, a Scrum Master, or a stakeholder, information is incredibly important.  This project is an example of what one can do with the elegance of an open source solution such as [Dashing.io](http://dashing.io) and the power of the best Agile Software Development tool -- [VersionOne](http://www.versionone.com) (full disclosure -- I work at VersionOne as an Agile Coach/Consultant). I was inspired by both the request for such a thing from customers as well as my own desire to learn and produce something others could value and learn from.  The result, I think, is pretty darn cool -- and functional.  

Dashing.io is a great solution from the folks at Shopify.  It is based on Ruby and leverages several other open source projects. It has some limitations around deployment/scaling and it's not responsive, but these are minor compared to the value it provides and overall ease of use. Check out http://shopify.github.com/dashing for more information.

The dashboard itself is targeted for agile teams that predominantly iterate (i.e. they have sprints) and they are at that point in their adoption that they find value in seeing the cycletime and looking at the cumulative flow.

## Getting Started

1. Make sure you have Ruby installed (der :) ).  
1. Once you have Ruby in place, get Dashing.io working.  Their [Getting Started](http://dashing.io/#setup) section spells out the steps.

   *NOTE - When you create your first dashboard, name it* `v1dashing`.

1. Edit the `Gemfile`, add:

   ```ruby
   gem 'httparty'
   gem 'nokogiri'
   ```

1. Execute `bundle`.
1. Create a new file in the `lib` directory of your dashboard called `v1conn.rb`.
2. Add the following contents to the file, changing the baseurl, username, and password to be able to connect to your VersionOne instance.
 
   ```ruby
   class V1conn
      def initialize
   		   @user = "username"
   		   @pass = "password"
   		   @auth = {:username => user, :password => pass}
   		   @baseurl = "http://address/instancename"
   	   end
   
   	   attr_accessor :user
   	   attr_accessor :pass
   	   attr_accessor :auth
   	   attr_accessor :baseurl
   end
   ```

1. Now the fun part, pick your widgets from the next section that you want to use and follow the setup and usage instructions.

   *NOTE - Like installing and developing anything, I suggest testing as you go -- you don't know what may go wrong.  So try one widget at a time.*

## VersionOne Enabled Widgets

| Widget | Description | Roadmap |
|--------|-------------|------------------|
| Conversations | Randomly rotates through the Conversations that impact a particularly configured TeamRoom. | |
| Cumulative Flow | A standard cumulative flow based on total Estimate points that uses the Statuses based on the Project provided, this can be optionally configured to accept a Team | Add ability to filter based on Program. |
| Cycle Time | Calculates the time it takes to move from one Status within a Project to another -- progression through the SDLC, calculated in days. This is calculated by Project and takes in the number of days to consider as well as the From and To Status. | |
| Days Left In Sprint | Calculates the number of days left in sprint based on the end date of the current active sprint.  Based on Project specified. | Optionally have it take in the Sprint Schedule. |
| Defects by Priority | A pie chart that shows the number of open defects for a specific Project and the current active sprint. Optionally can be configured by Team. | No reason to not have more dimensions -- Status, Feature Group, etc. |
| Epic Progress | Shows the percentage complete for Epics associated with Project configured.  The Type of Epic is required.  The Team can be optionally specified. | |
| [Sprint Burndown](https://gist.github.com/mtbadgley/fc81d71152dd32ec5829) | A standard sprint burndown based on the total remaining To Do. This can be configured against a particular Project backlog and optionally, a Team. | Add Sprint Schedule as a required filter, and make Project optional. |
| Story Progress | Shows the percentage complete of Stories based on the detail estimate less the remaining work over the detail estimate.  Does not consider Done or Effort in the formula. Configured based on Project, shows for the current active Sprint.  Optionally can configure the Team. | Optionally include Test Sets and Defects. Add the ability to see the ID. |
| Velocity | Calculates the velocity average for the last three closed sprints.  Configured the Project and Team. | Add the current planned amount. |

## Technical Details

This project was developed using Ruby 2.0.0p451 (2014-02-24 revision 45167).  [HTTParty](http://johnnunemaker.com/httparty/) and [Nokogiri](http://nokogiri.org) are used to make the calls to the VersionOne's API. 

The authentication with VersionOne uses [Basic Authentication](http://community.versionone.com/Developers/Developer-Library/Documentation/API/Security/Application_Authentication/Basic_Authentication).  VersionOne does support [OAuth 2.0](http://community.versionone.com/Developers/Developer-Library/Documentation/API/Security/Oauth_2.0_Authentication), but to get this project out there in the ether -- I chose to leverage Basic Auth initially.  Check back for modifications that will leverage OAuth 2.0.

Most calls to VersionOne used the [query.v1](http://community.versionone.com/Developers/Developer-Library/Documentation/API/Endpoints/query.v1) endpoint.  This endpoint will take in JSON or YAML query payload and return JSON.  The nice thing about the query.v1 endpoint is that you can make combined queries or [multiple queries](http://community.versionone.com/Developers/Developer-Library/Recipes/Query_for_Burndown_Data) in one request; thus, reducing the round trips.  It also has this great grouping mechanism.  

The only situation I needed to use the legacy [rest-1.v1](http://community.versionone.com/Developers/Developer-Library/Documentation/API/Endpoints/rest-1.v1%2F%2FData) endpoint which is a querystring argument returning XML was for the Cycle Time calculation.  This is because the ability to look back in [history](http://community.versionone.com/Developers/Developer-Library/Documentation/API/Endpoints/rest-1.v1%2F%2FHist) and grab a specific value based on another attribute is  not available in the query.v1.  For this, I used Nokogiri to parse the XML and it worked great!

## DISCLAIMER

The licenses for VersionOne is covered through your agreement with [VersionOne](http://www.versionone.com).  And for Dashing.io, it is covered under [MIT License](https://github.com/Shopify/dashing/blob/master/MIT-LICENSE).  As for this work, it's not guaranteed and made as an example dashboard for those of you using VersionOne and wanting a really cool dashboard like what using Dashing.io can deliver.  This project is not maintained under any agreement with VersionOne or Dashing.io.

