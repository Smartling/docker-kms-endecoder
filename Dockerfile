FROM centos:7

ADD endecoder.rb /bin/endecoder.rb
RUN chmod +x /bin/endecoder.rb

RUN yum install unzip curl python rubygems-devel ruby-devel -y
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN gem install aws-sdk-core --no-ri --no-rdoc -V

RUN mkdir /root/.aws
RUN echo "[profile default]" > /root/.aws/config
RUN echo "region = us-east-1" >> /root/.aws/config

CMD ["/bin/endecoder.rb"]
