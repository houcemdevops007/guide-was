
# -*- coding: utf-8 -*-
# WebSphere ND 8.5.5
# Creation de 20 utilisateurs avec role administrator
# Mot de passe = nom utilisateur
# Uniquement pour environnement de formation isole

for i in range(1, 21):

    username = "efiadmin%d" % i
    password = username

    try:
        print "Creation utilisateur : " + username

        AdminTask.createUser([
            '-uid', username,
            '-password', password,
            '-confirmPassword', password,
            '-cn', username,
            '-sn', 'EFI'
        ])

        AdminConfig.save()

        print "Utilisateur cree : " + username

    except:
        print "ERREUR creation utilisateur : " + username

    try:
        AdminTask.mapUsersToAdminRole([
            '-roleName', 'administrator',
            '-userids', username
        ])

        AdminConfig.save()

        print "Role administrator attribue : " + username

    except:
        print "ERREUR attribution role : " + username

print "Traitement termine."
