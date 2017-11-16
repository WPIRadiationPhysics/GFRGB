%{
  Gafchromic Film RGB Analyzer
  Shaun Marshall
  https://www.github.com/r/WPIRadiationPhysics/GFRGB

  Allows user to view max/min values of RGB channels in
  selected region of exposed film images.*

  *Initial project goal was to create seek basic image
   grayscale seek algorithm- this code has since begun
   to specialize with dosimetric analysis tools, with
   which the global seek function has been temporarily
   suppressed. A renewal of the initial feature is in
   the works.

   Last updated 2016-11-14
%}

%% Initialize Menu GUI (Analyzer invoked within)
gfrgb_menu
