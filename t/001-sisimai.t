use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai;
use JSON;

my $PackageName = 'Sisimai';
my $MethodNames = {
    'class' => ['sysname', 'libname', 'version', 'make', 'dump', 'engine'],
    'object' => [],
};
my $SampleEmail = {
    'mailbox' => './set-of-emails/mailbox/mbox-0',
    'maildir' => './set-of-emails/maildir/bsd',
};
my $IsNotBounce = {
    'maildir' => './set-of-emails/maildir/not',
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {

    is $PackageName->sysname, 'bouncehammer', '->sysname = bouncehammer';
    is $PackageName->libname, $PackageName, '->libname = '.$PackageName;
    is $PackageName->version, $Sisimai::VERSION, '->version = '.$Sisimai::VERSION;
    is $PackageName->make(undef), undef;
    is $PackageName->dump(undef), undef;

    # Wrong number of arguments
    eval { $PackageName->make('/dev/null', undef), undef };
    like $@, qr/error: wrong number of arguments/;

    eval { $PackageName->dump('/dev/null', undef), undef };
    like $@, qr/error: wrong number of arguments/;

    for my $e ( 'mailbox', 'maildir' ) {
        MAKE: {
            my $parseddata = $PackageName->make($SampleEmail->{ $e });
            my $damnedhash = undef;
            my $jsonstring = undef;
            isa_ok $parseddata, 'ARRAY';
            ok scalar @$parseddata, 'entries = '.scalar @$parseddata;

            for my $ee ( @$parseddata ) {
                isa_ok $ee, 'Sisimai::Data';
                isa_ok $ee->timestamp, 'Sisimai::Time';
                isa_ok $ee->addresser, 'Sisimai::Address';
                isa_ok $ee->recipient, 'Sisimai::Address';
                ok $ee->addresser->address, '->addresser = '.$ee->addresser->address;
                ok $ee->recipient->address, '->recipient = '.$ee->recipient->address;
                ok length  $ee->reason, '->reason = '.$ee->reason;
                ok defined $ee->replycode, '->replycode = '.$ee->replycode;

                $damnedhash = $ee->damn;
                isa_ok $damnedhash, 'HASH';
                ok scalar keys %$damnedhash;
                is $damnedhash->{'recipient'}, $ee->recipient->address, '->recipient = '.$damnedhash->{'recipient'};
                is $damnedhash->{'addresser'}, $ee->addresser->address, '->addresser = '.$damnedhash->{'addresser'};

                for my $eee ( keys %$damnedhash ) {
                    next if ref $ee->$eee;
                    next if $eee eq 'subject';
                    is $damnedhash->{ $eee }, $ee->$eee, '->'.$eee.' = '.$damnedhash->{ $eee };
                }

                $jsonstring = $ee->dump('json');
                ok length $jsonstring, 'length(dump("json")) = '.length $jsonstring;
            }
        }

        DUMP: {
            my $jsonstring = $PackageName->dump($SampleEmail->{ $e });
            my $perlobject = undef;
            my $tobetested = [ qw|
                addresser recipient senderdomain destination reason timestamp 
                token smtpagent|
            ];
            ok length $jsonstring;
            utf8::encode $jsonstring if utf8::is_utf8 $jsonstring;
            $perlobject = JSON::decode_json($jsonstring);

            isa_ok $perlobject, 'ARRAY';
            for my $ee ( @$perlobject ) {
                isa_ok $ee, 'HASH';
                for my $eee ( @$tobetested ) {
                    ok $ee->{ $eee }, $eee.' = '.$ee->{ $eee };
                }
            }
        }
    }

    for my $e ( 'maildir' ) {
        my $parseddata = $PackageName->make($IsNotBounce->{ $e });
        my $jsonstring = $PackageName->dump($IsNotBounce->{ $e });
        is $parseddata, undef, '->make = undef';
        is $jsonstring, '[]', '->dump = "[]"';
    }

    ENGINE: {
        my $enginelist = $PackageName->engine;
        isa_ok $enginelist, 'HASH';
        ok scalar(keys %$enginelist), '->engine = '.scalar(keys %$enginelist);
        for my $e ( keys %$enginelist ) {
            like $e, qr/\ASisimai::/, '->engine = '.$e;
            ok length $enginelist->{ $e }, '->engine->{'.$e.'} = '.$enginelist->{ $e };
        }
    }

    REASON: {
        my $reasonlist = $PackageName->reason;
        isa_ok $reasonlist, 'HASH';
        ok scalar(keys %$reasonlist), '->reason = '.scalar(keys %$reasonlist);
        for my $e ( keys %$reasonlist ) {
            like $e, qr/\A[A-Z]/, '->reason = '.$e;
            ok length $reasonlist->{ $e }, '->reason->{'.$e.'} = '.$reasonlist->{ $e };
        }
    }
}
done_testing;

