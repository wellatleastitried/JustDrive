FROM perl:latest

RUN cpanm Mojolicious JSON Net::GPSD3 Term::ReadKey File::Slurp Term::ANSIColor IPC::System::Simple

WORKDIR /usr/src/wardriver

COPY scripts/ /usr/src/wardriver/scripts/
COPY data/ /usr/src/wardriver/data/

EXPOSE 3000

CMD ["perl", "scripts/justDrive"]
