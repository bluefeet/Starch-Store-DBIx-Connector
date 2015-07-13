package Starch::Store::DBIx::Connector;

=head1 NAME

Starch::Store::DBIx::Connector - Session storage backend using DBIx::Connector.

=head1 SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::DBIx::Connector',
            connector => [
                $dsn,
                $username,
                $password,
                { RaiseError=>1, AutoCommit=>1 },
            ],
            table => 'my_sessions',
        },
    );

=head1 DESCRIPTION

This L<Starch> store uses L<DBIx::Connector> to set and get session data.

Very little is documented in this module as it is just a subclass
of L<Starch::Store::DBI> modified to use L<DBIx::Connector>
instead of L<DBI>.

=cut

use DBIx::Connector;
use Types::Standard -types;
use Scalar::Util qw( blessed );

use Moo;
use strictures 2;
use namespace::clean;

extends 'Starch::Store::DBI';

sub BUILD {
  my ($self) = @_;

  # Get this loaded as early as possible.
  $self->connector();

  return;
}

=head1 REQUIRED ARGUMENTS

=head2 connector

This must be set to either an array ref arguments for L<DBIx::Connector>
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
L<method proxy|Starch::Manual/METHOD PROXIES>
is a good way to link your existing L<DBIx::Connector> object
constructor in with Starch so that starch doesn't build its own.

=cut


has '+_dbh_arg' => (
    isa      => InstanceOf[ 'DBIx::Connector' ] | ArrayRef,
    init_arg => 'connector',
    reader   => '_connector_arg',
);

has '+dbh' => (
    isa      => InstanceOf[ 'DBIx::Connector' ],
    init_arg => undef,
    reader   => 'connector',
    builder  => '_build_connector',
);
sub _build_connector {
    my ($self) = @_;

    my $connector = $self->_connector_arg();
    return $connector if blessed $connector;

    return DBIx::Connector->new( @$connector );
}

=head1 METHODS

=head2 set

Set L<Starch::Store/set>.

=head2 get

Set L<Starch::Store/get>.

=head2 remove

Set L<Starch::Store/remove>.

=cut

# Little clean hack to make all of the DBI code "just work".
# local() can be awesome.
our $dbh;
sub dbh { $dbh }

around qw( set get remove ) => sub{
    my ($orig, $self, @args) = @_;

    return $self->connector->txn(sub{
        local $dbh = $_;

        return $self->$orig( @args );
    });
};

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Store-DBIx-Connector GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Store-DBIx-Connector/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

