use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::MTA::X1;

my $PackageName = 'Sisimai::MTA::X1';
my $EmailPrefix = 'x1';
my $MethodNames = {
    'class' => [ 
        'version', 'description', 'headerlist', 'scan',
        'SMTPCOMMAND', 'DELIVERYSTATUS', 'RFC822HEADERS',
    ],
    'object' => [],
};
my $ReturnValue = {
    '01' => { 'status' => qr/\A5[.]0[.]\d+\z/, 'reason' => qr/filtered/ },
    '02' => { 'status' => qr/\A5[.]0[.]\d+\z/, 'reason' => qr/filtered/ },
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    my $v = undef;
    my $c = 0;

    $v = $PackageName->version;
    ok $v, '->version = '.$v;
    $v = $PackageName->description;
    ok $v, '->description = '.$v;

    $v = $PackageName->smtpagent;
    ok $v, '->smtpagent = '.$v;

    is $PackageName->scan, undef, '->scan';

    use Sisimai::Data;
    use Sisimai::Mail;
    use Sisimai::Message;

    PARSE_EACH_MAIL: for my $n ( 1..20 ) {

        my $emailfn = sprintf( "./eg/maildir-as-a-sample/new/%s-%02d.eml", $EmailPrefix, $n );
        my $mailbox = Sisimai::Mail->new( $emailfn );
        my $emindex = sprintf( "%02d", $n );
        next unless defined $mailbox;
        ok -f $emailfn, 'email = '.$emailfn;

        while( my $r = $mailbox->read ) {

            my $p = Sisimai::Message->new( 'data' => $r );
            my $o = undef;
            isa_ok $p, 'Sisimai::Message';
            isa_ok $p->ds, 'ARRAY';
            isa_ok $p->header, 'HASH';
            isa_ok $p->rfc822, 'HASH';
            ok length $p->from;

            for my $e ( @{ $p->ds } ) {
                ok length $e->{'recipient'}, '->recipient = '.$e->{'recipient'};
                ok length $e->{'diagnosis'}, '->diagnosis = '.$e->{'diagnosis'};
                is $e->{'agent'}, 'X1', '->agent = '.$e->{'agent'};

                ok exists $e->{'date'}, '->date = '.$e->{'date'};
                ok exists $e->{'spec'}, '->spec = '.$e->{'spec'};
                ok exists $e->{'reason'}, '->reason = '.$e->{'reason'};
                ok exists $e->{'status'}, '->status = '.$e->{'status'};
                ok exists $e->{'command'}, '->command = '.$e->{'command'};
                ok exists $e->{'action'}, '->action = '.$e->{'action'};
                ok exists $e->{'rhost'}, '->rhost = '.$e->{'rhost'};
                ok exists $e->{'lhost'}, '->lhost = '.$e->{'lhost'};
                ok exists $e->{'alias'}, '->alias = '.$e->{'alias'};
                ok exists $e->{'feedbacktype'}, '->feedbacktype = ""';
                ok exists $e->{'softbounce'}, '->softbounce = '.$e->{'softbounce'};

                like $e->{'recipient'}, qr/[0-9A-Za-z@-_.]+/, '->recipient = '.$e->{'recipient'};
            }

            $o = Sisimai::Data->make( 'data' => $p );
            ok scalar @$o, 'entry = '.scalar @$o;
            for my $e ( @$o ) {
                isa_ok $e, 'Sisimai::Data';
                like $e->deliverystatus, $ReturnValue->{ $emindex }->{'status'}, '->status = '.$e->deliverystatus;
                like $e->reason, $ReturnValue->{ $emindex }->{'reason'}, '->reason = '.$e->reason;
                unlike $e->lhost, qr/[ ]/, '->lhost = '.$e->lhost;
                unlike $e->rhost, qr/[ ]/, '->rhost = '.$e->rhost;
                unlike $e->listid, qr/[ ]/, '->listid = '.$e->listid;
                unlike $e->messageid, qr/[ ]/, '->messageid = '.$e->messageid;
                ok defined $e->replycode, '->replycode = '.$e->replycode;
            }
            $c++;
        }
    }
    ok $c, 'the number of emails = '.$c;
}
done_testing;

