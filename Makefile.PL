# Note: this file was auto-generated by Module::Build::Compat version 0.4007
require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile
(
  'NAME' => 'POE::Component::IRC::Plugin::CSS::Minifier',
  'VERSION_FROM' => 'lib/POE/Component/IRC/Plugin/CSS/Minifier.pm',
  'PREREQ_PM' => {
                   'POE::Component::CSS::Minifier' => '0.0101',
                   'POE::Component::IRC::Plugin::BasePoCoWrap' => '0.005',
                   'POE::Component::IRC::Plugin::OutputToPastebin' => '0.001',
                   'Test::More' => 0
                 },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [],
  'PL_FILES' => {}
)
;
