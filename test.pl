#!/usr/local/bin/perl

use lib './';
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
		'data' => "From: \"from\" <from\@localhost>\nTo: \"rcpt\" <rcpt\@localhost>\nSubject: Test\n\nTesting...\n"
	}
};

my $nugget = EmailNugget->new($message);
$nugget->write_to("write_to.test");
my $open_nugget = EmailNugget->new_from("new_from.test");

print $open_nugget->data;
