use strict;
use warnings;

our $VERSION = '0.2'; # 62bafe89f02df73
our %IRSSI = (
    authors     => 'Nei, tslocum',
    contact     => 'Nei @ anti@conference.jabber.teamidiot.de',
    url         => "http://anti.teamidiot.de/",
    name        => 'away_notify',
    description => 'Implement support for IRCv3.1 AWAY messages (does not auto-request the cap atm)',
    license     => 'ISC',
);

# This script will immediately update the internal away state of users
# on synced channels if the server supports the IRCv3.1 away-notify
# function and you have enabled it. This can be used in conjunction
# with /anames or tmux-nicklist-portable instead of the autowho script
# on supporting server.

# Options
# =======
# /set away_notify_public <ON|OFF>
# * whether to write the away state to channel windows
#
# /format notify_away_channel
# * the format to use when printing away messages is enabled and the
#   user goes away
#
# /format notify_unaway_channel
# * the format to use when printing away messages is enabled and the
#   user comes back

use Irssi;

Irssi::theme_register([
  'notify_away_channel'   => '{channick $0} {chanhost $1} is now away: {reason $3}',
  'notify_unaway_channel' => '{channick_hilight $0} {chanhost $1} is no longer away',
]);

sub request_caps {
    my @servers = Irssi::servers();
    foreach my $server(@servers) {
        if ($server->{connected}) {
            $server->command("CAP LS");
        }
    }
}

sub irc_event_cap {
    my ($server, $args, $nick, $address) = @_;
    if ($args =~ /^\S+ (\S+) :(.*)$/) {
        if (uc $1 eq 'LS' && $2 =~ / away-notify /i) {
            $server->command("CAP REQ :away-notify");
        }
    }
}

sub irc_event_away {
    my ($server, $data, $nick, $userhost) = @_;
    return unless $server->isa('Irssi::Irc::Server');
    my @allchans = $server->nicks_get_same($nick);
    my $n = $allchans[1];
    return unless $n;
    $data =~ s/^://;
    Irssi::signal_emit('userhost event', $server,
                       $server->{nick}. ' :' . $nick . ($n->{serverop}?'*':'')
                           . '=' . (length $data ? '-' : '+') 
                           . $userhost);
    if (Irssi::settings_get_bool('away_notify_public')) {
        for (my $i = 0; $i < @allchans; $i += 2) {
            next unless $allchans[$i];
            $allchans[$i]->printformat(MSGLEVEL_MODES, (length $data ? 'notify_away_channel' : 'notify_unaway_channel'),
                                       $nick, $userhost, $allchans[$i]->{visible_name}, $data); 
        }
    }
}

Irssi::signal_register({'userhost event'=>[qw[iobject string]]});
Irssi::settings_add_bool('lookandfeel', 'away_notify_public', 0);
Irssi::signal_add('event cap', 'irc_event_cap');
Irssi::signal_add('event away', 'irc_event_away');

request_caps();
