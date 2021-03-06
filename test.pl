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
		'misc' => {
			'test_tag_1' => "Hello World!\n",
			'test_tag_2' => "Test tag 2!\n",
		},
		'id' => 'asdfasdfasdf',
		'context' => 'inbound'
	},
	'message' => {
		'data' => "From: \"from\" <from\@localhost>\nTo: \"rcpt\" <rcpt\@localhost>\nSubject: Test from data\n\nTesting...\n"
	},
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

eval {
	$from_email_file->write_to('/this/path/doesnt/exist.txt');
};
if ($@) {
	print "Failed to save nugget: $@";
}
