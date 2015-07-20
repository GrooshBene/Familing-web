FROM node
RUN mkdir -p /usr/src/app
RUN wget http://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.21/GraphicsMagick-1.3.21.tar.gz -O /usr/src/GraphicsMagick-1.3.21.tar.gz
WORKDIR /usr/src/
RUN tar -xvf GraphicsMagick-1.3.21.tar.gz
WORKDIR /usr/src/GraphicsMagick-1.3.21
RUN ./configure --disable-shared --disable-installed
RUN make install
ENV PATH /usr/local/bin:$PATH
WORKDIR /usr/src/app
COPY package.json /usr/src/app/
RUN npm install
COPY . /usr/src/app
EXPOSE 8000
CMD [ "npm", "start" ]
