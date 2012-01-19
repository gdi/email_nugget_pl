#!/usr/local/bin/perl

use lib './';
use Data::Dumper;
use EmailNugget;
use Scalar::Util qw(reftype);

my $message = {
	'envelope' => {
		'mail_from' => "from\@localhost",
		'rcpt_to' => ["rcpt1\@localhost", "rcpt2\@localhost", "rcpt3\@localhost"],
		'helo' => "localhost\n\n",
		'adsf' => "weeee",
	},
	'message' => {
		'data' => "From: \"from\" <from\@localhost>\nTo: \"rcpt\" <rcpt\@localhost>\nSubject: Test from data\n\nTesting...\n"
	}
};

my $nugget = EmailNugget->new($message);
$nugget->write_to("test_files/write_to_from_data.test");

my $from_nugget_file = EmailNugget->new_from_nugget("test_files/new_from_nugget.test");
$from_nugget_file->write_to("test_files/write_to_from_nugget.test");

my $from_email_file = EmailNugget->new_from_email("test_files/new_from_email.test", $message->{'envelope'});
$from_email_file->write_to("test_files/write_to_from_email.test");

while (my $line = $from_email_file->stream_message()) {
	print $line;
}
