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
		'data' => "asdfasdfasdfasdfasdf.\n"
	}
};

my $nugget = EmailNugget->new($message);
$nugget->write_to("write_to.test");
my $open_nugget = EmailNugget->new_from("new_from.test");
