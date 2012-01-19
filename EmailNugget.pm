package EmailNugget;

use strict;
use Data::UUID;
use JSON;
use Digest::MD5 qw(md5_hex);
use Scalar::Util "reftype";

sub new {
	my $class = shift;
	my $args = shift;

	my $self = {
		message => {
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
		},
		id => $args->{'id'},
	};
	bless $self, $class;
	$self->set_recipients();
	$self->ensure_id();
	$self->ensure_fields();
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
	$self->{id} = $self->generate_id() if (!$self->{id});
}

sub ensure_fields {
	my ($self) = @_;
	foreach my $key (keys %{$self->{envelope}}) {
		next if ($key eq 'rcpt_to');
		$self->{envelope}->{$key} = "" if (!$self->{envelope}->{$key});
		$self->{envelope}->{$key} =~ s/\n//g;
	}
	foreach my $key (keys %{$self->{message}}) {
		$self->{message}->{$key} = "" if (!$self->{message}->{$key});
	}
}

sub checksum {
	my ($self) = @_;
	return $self->{message}->{checksum} if ($self->{message}->{checksum});
	my $checksum = md5_hex($self->{message}->{data});
	$self->{message}->{checksum} = $checksum;
	return $checksum;
}

sub data {
	my ($self) = @_;
	return $self->{message}->{data};
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
	my $response = {
		'data' => $self->data,
		'checksum' => $self->checksum,
	};
	return ($response);
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

sub new_from {
	my ($class, $file_path) = @_;
	return undef if (! -e $file_path);
	open(NUGGET, $file_path) || return undef;
	my $json_envelope = <NUGGET>;
	chomp($json_envelope);
	my $json = JSON->new->allow_nonref;

	my $args = {};
	$args->{envelope} = $json->decode($json_envelope);
	my $checksum = <NUGGET>;
	chomp($checksum);
	$args->{message}->{checksum} = $checksum;
	my $message = "";
	while (my $line = <NUGGET>) {
		$message = $message . $line;
	}
	$args->{message}->{data} = $message;
	close(NUGGET);
	return EmailNugget->new($args);
}

sub write_to {
	my ($self, $file_path) = @_;
	open(NUGGET, ">$file_path") || return -1;
	my $json = JSON->new->allow_nonref;
	print NUGGET $json->encode($self->{envelope}) . "\n";
	print NUGGET $self->checksum . "\n";
	print NUGGET $self->{message}->{data};
	close(NUGGET);
}

1;
