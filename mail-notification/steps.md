# Setting up E-Mail alerts

## First set up writing emails

```bash
sudo apt-get install ssmtp 

sudo mkdir /etc/ssmtp
sudo vim /etc/ssmtp/ssmtp.conf
```

add this and comment the rest of the file:

```ini
root=your.mail@gmail.com
mailhub=smtp.gmail.com:465
FromLineOverride=YES
AuthUser=your.mail@gmail.com
AuthPass=passcode
UseTLS=YES
```

get the passcode for your gmail-Account from here:
https://security.google.com/settings/security/apppasswords

You need to remove the spaces, do not put the code into braces, else it won't work.

Test whether it works:

```bash
echo "Test" | ssmtp target@anymail.com
```

## Writing Mails automatically

Now to get the results automatically send to you, you nedd to do this:

Create directory on your Home-Folder on the Raspberry:

```bash
mkdir mail-notifications
```

Now you need to create a file name "mail-header". In there specify your target mail-address.

```bash
to: target@anymail.com # change this line
From: your.mail@gmail.com # and this line
MIME-Version: 1.0
Content-Type: text; charset=utf-8
Subject: These files were changed on your server
```

Copy the files "make-table.py" and "send-mail.sh into it. And give permissions to be executed:

```bash
chmod ~/mail-notifications/send-mail.sh
```

Now set up a cronjob to get the notification every day:

```bash
crontab -e
```

```bash
Add this line
0 6 * * * ~/mail-notifications/send-mail
```
