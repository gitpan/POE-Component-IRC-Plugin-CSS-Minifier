package POE::Component::IRC::Plugin::CSS::Minifier;

use warnings;
use strict;

our $VERSION = '0.0102';

use base 'POE::Component::IRC::Plugin::BasePoCoWrap';
use POE::Component::CSS::Minifier;

sub _make_default_args {
    return (
        pastebin_trigger => '[irc_to_pastebin]',
        response_event   => 'irc_css_minifier',
        trigger          => qr/^minify\s*css\s+(?=\S)/i,
    );
}

sub _make_poco {
    my $self = shift;
    return POE::Component::CSS::Minifier->spawn(
        debug => $self->{debug},
        %{ $self->{obj_args} || {} },
    );
}

sub _make_response_message {
    my $self   = shift;
    my $in_ref = shift;

    my $prefix = '';

    $in_ref->{_type} eq 'public'
        and $prefix = (split /!/, $in_ref->{_who})[0] . ', ';

    exists $in_ref->{error}
        and return "$prefix$in_ref->{error}";

    return "$prefix see $self->{pastebin_trigger}$in_ref->{out}";
}

sub _message_into_response_event { 'out' }

sub _make_poco_call {
    my $self = shift;
    my $data_ref = shift;

    $self->{poco}->minify( {
            event       => '_poco_done',
            uri         => delete $data_ref->{what},
            map +( "_$_" => $data_ref->{$_} ),
                keys %$data_ref,
        }
    );
}
1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::CSS::Minifier - plugin to "minify" CSS code

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(
        Component::IRC
        Component::IRC::Plugin::OutputToPastebin
        Component::IRC::Plugin::CSS::Minifier
    );

    my $irc = POE::Component::IRC->spawn(
        nick        => 'CSSMinifierBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'CSSMinifierBot',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'Paster' =>
                POE::Component::IRC::Plugin::OutputToPastebin->new
        );

        $irc->plugin_add(
            'CSSMinifier' =>
                POE::Component::IRC::Plugin::CSS::Minifier->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> CSSMinifierBot, minify css http://zoffix.com/new/del/test.css
    <CSSMinifierBot> Zoffix,  see http://erxz.com/pb/13213

    <Zoffix> CSSMinifierBot, minify css http://zoffix.com/new/del/not_found.css
    <CSSMinifierBot> Zoffix, 404 Not Found

=head1 IMPORTANT IMPORTANT IMPORTANT

Unless you are going to manually generate responses into IRC from events or you enjoy
huge spams, you need to use L<POE::Component::IRC::Plugin::OutputToPastebin> along with
this module.

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
fetch CSS code from URIs, "minify" the code using L<CSS::Minifier> and
pastebin the result.
The plugin accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

The plugin is non-blocking.

=head1 CONSTRUCTOR

=head2 C<new>

    # plain and simple
    $irc->plugin_add(
        'CSSMinifier' => POE::Component::IRC::Plugin::CSS::Minifier->new
    );

    # juicy flavor
    $irc->plugin_add(
        'CSSMinifier' =>
            POE::Component::IRC::Plugin::CSS::Minifier->new(
                auto             => 1,
                response_event   => 'irc_css_minifier',
                banned           => [ qr/aol\.com$/i ],
                addressed        => 1,
                root             => [ qr/mah.net$/i ],
                trigger          => qr/^minify\s*css\s+(?=\S)/i,
                triggers         => {
                    public  => qr/^minify\s*css\s+(?=\S)/i,
                    notice  => qr/^minify\s*css\s+(?=\S)/i,
                    privmsg => qr/^minify\s*css\s+(?=\S)/i,
                },
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::CSS::Minifier> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 C<auto>

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 C<response_event>

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_css_minifier>

=head3 C<banned>

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 C<root>

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 C<trigger>

    ->new( trigger => qr/^minify\s*css\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex, irrelevant of the type of the message, will be considered as requests. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data (the URI to fetch) that needs to be processed.
B<Defaults to:> C<qr/^minify\s*css\s+(?=\S)/i>

=head3 C<triggers>

    ->new( triggers => {
            public  => qr/^minify\s*css\s+(?=\S)/i,
            notice  => qr/^minify\s*css\s+(?=\S)/i,
            privmsg => qr/^minify\s*css\s+(?=\S)/i,
        }
    );

B<Optional>. Takes a hashref as an argument which may contain either
one or all of keys B<public>, B<notice> and B<privmsg> which indicates
the type of messages: channel messages, notices and private messages
respectively. The values of those keys are regexes of the same format and
meaning as for the C<trigger> argument (see above).
Messages matching this
regex will be considered as requests. The difference is that only messages of type corresponding to the key of C<triggers> hashref
are checked for the trigger. B<Note:> the C<trigger> will be matched
irrelevant of the setting in C<triggers>, thus you can have one global and specific "local" triggers. See also
B<addressed> option below which is enabled by default as well as
B<trigggers> option which is more specific. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^minify\s*css\s+(?=\S)/i>

=head3 C<addressed>

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig EXAMPLE>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 C<listen_for_input>

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 C<eat>

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 C<debug>

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITED EVENTS

=head2 C<response_event>

    $VAR1 = {
        'uri' => 'http://zoffix.com/new/del/test.css'
        'out' => 'Zoffix,  see [irc_to_pastebin]*{margin:0;padding:0;}html{height:100%;}',
        '_channel' => '#zofbot',
        '_type' => 'public',
        '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        '_message' => 'CSSMinifierBot, minify css http://zoffix.com/new/del/test.css',
    };

    $VAR1 = {
        'uri' => 'http://zoffix.com/new/del/not_found.css',
        'error' => '404 Not Found'
        'out' => 'Zoffix, 404 Not Found',
        '_channel' => '#zofbot',
        '_type' => 'public',
        '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        '_message' => 'CSSMinifierBot, minify css http://zoffix.com/new/del/not_found.css',
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_css_minifier>) will recieve input
every time request is completed. The input will come in C<$_[ARG0]>
on a form of a hashref.
The possible keys/values of that hashrefs are as follows:

=head3 C<uri>

    { 'uri' => 'http://zoffix.com/new/del/test.css' }

The C<uri> key will contain the URI that the user specified to fetch CSS code from

=head3 C<out>

    { 'out' => 'Zoffix,  see [irc_to_pastebin]*{margin:0;padding:0;}html{height:100%;}', }

The C<out> key will contain what would be spoken to IRC when C<auto> constructor's argument
is set to a true value buy before L<POE::Component::IRC::Plugin::OutputToPastebin> would
get a hold of it.

=head3 C<error>

    { 'error' => '404 Not Found' }

If an error occured during the fetching of the URI, the C<error> key will be present and
its value will be a human parsable error message.

=head3 C<_who>

    { '_who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix', }

The C<_who> key will contain the user mask of the user who sent the request.

=head3 C<_message>

    { '_message' => 'CSSMinifierBot, minify css http://zoffix.com/new/del/not_found.css', }

The C<_message> key will contain the actual message which the user sent; that
is before the trigger is stripped.

=head3 C<_type>

    { '_type' => 'public', }

The C<_type> key will contain the "type" of the message the user have sent.
This will be either C<public>, C<privmsg> or C<notice>.

=head3 C<_channel>

    { '_channel' => '#zofbot', }

The C<_channel> key will contain the name of the channel where the message
originated. This will only make sense if C<_type> key contains C<public>.

=head1 SEE ALSO

L<POE::Component::IRC>, L<CSS::Minifier>

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-css-minifier at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-CSS-Minifier>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::CSS::Minifier

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-CSS-Minifier>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-CSS-Minifier>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-CSS-Minifier>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-CSS-Minifier>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

