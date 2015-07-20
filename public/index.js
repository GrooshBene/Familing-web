function statusChangeCallback(response) {
  console.log('statusChangeCallback');
  console.log(response);
  if (response.status === 'connected') {
    // Logged into your app and Facebook.
    testAPI(response);
  } else if (response.status === 'not_authorized') {
    // The person is logged into Facebook, but not your app.
    document.getElementById('status').innerHTML = 'Please log ' +
      'into this app.';
  } else {
    // The person is not logged into Facebook, so we're not sure if
    // they are logged into this app or not.
    document.getElementById('status').innerHTML = 'Please log ' +
      'into Facebook.';
  }
}

var apikey;
var user;
var groups;
var selectedGroup = 1;

var articleList = {};

function checkLoginState() {
  FB.getLoginStatus(function(response) {
    statusChangeCallback(response);
  });
}

window.fbAsyncInit = function() {
  FB.init({
    appId      : '655708987896404',
    cookie     : true,
    xfbml      : true,
    version    : 'v2.2'
  });

  FB.getLoginStatus(function(response) {
    statusChangeCallback(response);
  });

};

// Load the SDK asynchronously
(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/sdk.js";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

function testAPI(response) {
  document.getElementById('fblogin').style.display = 'none';
  document.getElementById('status').innerHTML = 'Obtaining API key';
  $.post('/api/auth/facebook/token/', {
    access_token: response.authResponse.accessToken
  }, function(data) {
    console.log(data);
    apikey = data.token;
    user = data;
    groups = data.groups;
    console.log(apikey);
    document.getElementById('status').innerHTML = 'Hello, '+data.name;
    updateGroups();
  });
}

function updateGroups() {
  $('#grouplist').html(groups.map(function(group) {
    return '<li>'+group.id+'# '+group.name+'-'+(group.description||'')+
    ' <a href="#" onclick="partGroup('+group.id+')">나가기</a>'+
    ' <a href="#" onclick="inspectGroup('+group.id+')">찾아보기</a></li>';
  }).join(''));
}

function updateAllGroups(groupList) {
  $('#groupalllist').html(groupList.map(function(group) {
    return '<li>'+group.id+'# '+group.name+'-'+(group.description||'')+
    ' <a href="#" onclick="joinGroup('+group.id+')">가입</a></li>';
  }).join(''));
}

function partGroup(id) {
  console.log(id);
  $.post('/api/group/self/part', {
    id: id,
    apikey: apikey
  }, function(data) {
    groups = data.groups;
    updateGroups();
  });
}

function fetchGroupAll() {
  $.post('/api/group/list', {
  }, function(data) {
    console.log(data);
    updateAllGroups(data);
  });
  return false;
}

function fetchGroup(name) {
  $.post('/api/group/search', {
    name: name
  }, function(data) {
    console.log(data);
    updateAllGroups(data);
  });
  return false;
}

function createGroup(name, description) {
  $.post('/api/group/self/create', {
    name: name,
    description: description,
    apikey: apikey
  }, function(data) {
    groups = data.groups;
    updateGroups();
  });
  return false;
}

function joinGroup(id) {
  $.post('/api/group/self/join', {
    id: id,
    apikey: apikey
  }, function(data) {
    groups = data.groups;
    updateGroups();
  });
  return false;
}

function inspectGroup(id) {
  $.post('/api/group/info', {
    id: id,
    apikey: apikey
  }, function(data) {
    $('#groupuserlist').html(data.users.map(function(user) {
      return '<li><img src="'+user.photo+'" width="32">'+user.id+'# '+user.name+'</li>';
    }).join(''));
  });
  selectedGroup = id;
  $('#groupcon').show();
  fetchArticle();
}

function fetchArticle() {
  $.post('/api/article/list', {
    group: selectedGroup,
    start: 65536
  }, function(data) {
    $('#articlelist').html(data.map(function(user) {
      articleList[user.id] = user;
      return '<li>'+user.id+'# '+user.name+' - '+user.description+
      ' <a href="#" onclick="readArticle('+user.id+')">읽기</a></li>';
    }).join(''));
  });
}

function readArticle(id) {
  var article = articleList[id];
  $('#articleview').html('<img src="'+article.photo+'">'+
    '<h1>'+article.name+'</h1>'+
    'type '+article.type+' category+'+article.category+
    'state '+article.state+'<br>'+
    '<p>'+article.description+'</p>'+
    '<p>'+article.reward+'</p>'+
    '<p>'+article.location+'</p>'+
    '<p> author '+article.author.name+'</p>');
}

function createArticle(data) {
  var p1 = new FormData();
  p1.append('name', data.name.value);
  p1.append('description', data.description.value);
  p1.append('group', selectedGroup);
  p1.append('type', data.type.value);
  p1.append('category', data.category.value);
  p1.append('reward', data.reward.value);
  p1.append('location', data.location.value);
  p1.append('apikey', apikey);
  p1.append('photo', data['photo'].files[0], data['photo'].files[0] && data['photo'].files[0].name);
  $.ajax({
    type: "POST",
    url: '/api/article/self/create',
    data: p1,
    processData: false,
    contentType: false,
    success: function(va) {
      console.log(va);
      fetchArticle();
    }
  });
  return false;
}
