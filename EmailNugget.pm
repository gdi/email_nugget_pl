package EmailNugget;

use strict;
use Data::UUID;
use Data::Dumper;
use JSON;
use Digest::MD5 qw(md5_hex);
use Scalar::Util "reftype";
use Fcntl ':flock';

sub new {
	my $class = shift;
	my $args = shift;

	my $self = {
		message => {
			'data_file' => $args->{'message'}->{'data_file'},
			'data' => $args->{'message'}->{'data'},
			'checksum' => $args->{'message'}->{'checksum'},
		},
		envelope => {
			'ip' => $args->{'envelope'}->{'ip'},
			'helo' => $args->{'envelope'}->{'helo'},
			'mail_from' => $args->{'envelope'}->{'mail_from'},
			'rcpt_to' => $args->{'envelope'}->{'rcpt_to'},
			'date' => $args->{'envelope'}->{'date'},
			'context' => $args->{'envelope'}->{'context'},
			'misc' => $args->{'envelope'}->{'misc'},
			'id' => $args->{'envelope'}->{'id'},
		},
	};
	bless $self, $class;
	$self->set_recipients();
	$self->ensure_id();
	return $self;
}

sub set_recipients {
	my ($self) = @_;
	if (reftype($self->{envelope}->{'rcpt_to'}) ne "ARRAY") {
		my $recipient = $self->{envelope}->{'rcpt_to'};
		$recipient =~ s/\n//g;
		$self->{envelope}->{'rcpt_to'} = [$recipient];
	}
	my $i = 0;
	foreach my $recipient (@{$self->{envelope}->{'rcpt_to'}}) {
		$self->{envelope}->{'rcpt_to'}[$i] =~ s/\n//g;
		$i++;
	}
}

sub ensure_id {
	my ($self) = @_;
	$self->{'envelope'}->{'id'} = $self->generate_id() unless ($self->{'envelope'}->{'id'});
}

sub checksum {
	my ($self) = @_;
	return $self->{message}->{checksum} if ($self->{message}->{checksum});
	my $checksum = md5_hex($self->data);
	$self->{message}->{checksum} = $checksum;
	return $checksum;
}

sub stream_message {
	my ($self) = @_;
	if (!$self->{message}->{data_file}->{stream_position}) {
		$self->{message}->{data_file}->{stream_position} = $self->{message}->{data_file}->{data_start_position};
	}
	open(DATA, $self->{message}->{data_file}->{path});
	seek(DATA, $self->{message}->{data_file}->{stream_position}, 0);
	if (my $line = <DATA>) {
		my $position = tell DATA;
		$self->{message}->{data_file}->{stream_position} = $position;
		return $line;
	} else {
		$self->{message}->{data_file}->{stream_position} = undef;
		return undef;
	}
}

sub data {
	my ($self) = @_;
	return $self->{message}->{data} if ($self->{message}->{data});
	my $message = "";
	if ($self->{message}->{data_file}->{path}) {
		open(DATA, $self->{message}->{data_file}->{path});
		seek(DATA, $self->{message}->{data_file}->{data_start_position}, 0);
		while (my $line = <DATA>) {
			$message = $message . $line;
		}
	}
	return $message;
}

sub ip {
	my ($self) = @_;
	return $self->{envelope}->{ip};
}

sub helo {
	my ($self) = @_;
	return $self->{envelope}->{helo};
}

sub mail_from {
	my ($self) = @_;
	return $self->{envelope}->{mail_from};
}

sub rcpt_to {
	my ($self) = @_;
	return $self->{envelope}->{rcpt_to};
}

sub date {
	my ($self) = @_;
	return $self->{envelope}->{date};
}

sub context {
	my ($self) = @_;
	return $self->{envelope}->{context};
}

sub message {
	my ($self) = @_;
	return ($self->{message});
}

sub json_envelope {
	my ($self) = @_;
	my $json = JSON->new->allow_nonref;
	return $json->encode($self->{envelope}) . "\n";
}

sub envelope {
	my ($self) = @_;
	return $self->{envelope};
}

sub generate_id {
	my ($self) = @_;
	my $ug = new Data::UUID;
	my $uuid = lc($ug->to_string($ug->create()));
	$uuid =~ s/\-//g;
	return $uuid;
}

sub new_from_email {
	my ($class, $file_path, $envelope) = @_;
	return undef if (! -e $file_path);
	open(EMAIL, $file_path) || return undef;
	my $position = tell EMAIL;
	my $ctx = Digest::MD5->new;
	$ctx->addfile(*EMAIL);
	my $checksum = $ctx->hexdigest;
	close(EMAIL);
  
	$envelope->{'misc'} ||= {};
  
	my $nugget_hash = {
		'envelope' => $envelope,
		'message' => {
			'data_file' => {
				'path' => $file_path,
				'data_start_position' => $position,
			},
			'checksum' => $checksum
		},
	};
	$nugget_hash->{'id'} = $envelope->{'id'} if ($envelope->{'id'});
	return EmailNugget->new($nugget_hash);
}

sub new_from_nugget {
	my ($class, $file_path) = @_;
	return undef if (! -e $file_path);
	open(NUGGET, $file_path) || return undef;
	my $json_envelope = <NUGGET>;
	chomp($json_envelope);
	my $json = JSON->new->allow_nonref;
	my $checksum = <NUGGET>;
	chomp($checksum);
	my $position = tell NUGGET;
	my $envelope = $json->decode($json_envelope);
	$envelope->{'misc'} ||= {};
	my $nugget_hash = {
		'envelope' => $envelope,
		'message' => {
			'data_file' => {
				'path' => $file_path,
				'data_start_position' => $position
			},
			'checksum' => $checksum
		},
	};
	$nugget_hash->{'id'} = $envelope->{'id'} if ($envelope->{'id'});
	return EmailNugget->new($nugget_hash);
}

sub write_to {
	my ($self, $file_path) = @_;
	open(NUGGET, ">$file_path") || die "Failed to open $file_path: $@\n";
	flock(NUGGET, LOCK_EX);
	my $json = JSON->new->allow_nonref;
	print NUGGET $json->encode($self->envelope()) . "\n";
	print NUGGET $self->checksum . "\n";
	if ($self->{message}->{data}) {
		print NUGGET $self->{message}->{data};
		close(NUGGET);
		return 1;
	} elsif ($self->{message}->{data_file}->{path}) {
		open(DATA, $self->{message}->{data_file}->{path});
		seek(DATA, $self->{message}->{data_file}->{data_start_position}, 0);
		while (my $line = <DATA>) {
			print NUGGET $line;
		}
		close(NUGGET);
		return 1;
	}
	die "Can't determine data for nugget\n";
}

1;
