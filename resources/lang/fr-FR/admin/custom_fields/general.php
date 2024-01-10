<?php

return [
    'custom_fields'		        => 'Champs personnalisés',
    'manage'                    => 'Gérer',
    'field'		                => 'Champ',
    'about_fieldsets_title'		=> 'A propos des fieldsets',
    'about_fieldsets_text'		=> 'Les jeux de champs permettent de grouper les champs supplémentaires affectés à des modèles d\'actifs.',
    'custom_format'             => 'Format Regex personnalisé...',
    'encrypt_field'      	        => 'Chiffrer la valeur de ce champ dans la base de données',
    'encrypt_field_help'      => 'AVERTISSEMENT: Chiffrer un champ en rend la recherche sur le contenu impossible.',
    'encrypted'      	        => 'Chiffré',
    'fieldset'      	        => 'Fieldset',
    'qty_fields'      	      => 'Qté de champs',
    'fieldsets'      	        => 'Fieldsets',
    'fieldset_name'           => 'Nom du fieldset',
    'field_name'              => 'Nom du champ',
    'field_values'            => 'Valeurs de champ',
    'field_values_help'       => 'Ajouter des options sélectionnables, une par ligne. Les lignes vides autres que la première ligne seront ignorées.',
    'field_element'           => 'Élément de formulaire',
    'field_element_short'     => 'Elément',
    'field_format'            => 'Format',
    'field_custom_format'     => 'Format personnalisé',
    'field_custom_format_help'     => 'Ce champ vous permet d\'utiliser une expression regex pour la validation. Il devrait commencer par "regex:" - par exemple, pour valider qu\'une valeur de champ personnalisée contient un IMEI valide (15 chiffres numériques), vous utiliseriez <code>regex: / ^[0-9]{15}$ /</code>.',
    'required'   		          => 'Requis',
    'req'   		              => 'Req.',
    'used_by_models'   		    => 'Utilisé par les modèles',
    'order'   		            => 'Commande',
    'create_fieldset'         => 'Nouveau Fieldset',
    'update_fieldset'         => 'Mettre à jour le Fieldset',
    'fieldset_does_not_exist'   => 'Le Fieldset :id n\'existe pas',
    'fieldset_updated'         => 'Fieldset mis à jour',
    'create_fieldset_title' => 'Créer un nouveau jeu de champs',
    'create_field'            => 'Nouveau champ personnalisé',
    'create_field_title' => 'Créer un champ personnalisé',
    'value_encrypted'      	        => 'La valeur de ce champ est chiffrée dans la base de donnée. Seuls les administrateurs seront capable de voir les données déchiffrées',
    'show_in_email'     => 'Inclure la valeur de ce champ dans les e-mails envoyés à l\'utilisateur·trice ? Les champs chiffrés ne peuvent pas être inclus dans les e-mails',
    'show_in_email_short'     => 'Inclure dans les emails.',
    'help_text' => 'Texte d\'aide',
    'help_text_description' => 'Ceci est un texte optionnel qui apparaîtra sous les éléments de formulaire lors de l\'édition d\'un actif pour fournir un contexte pour le champ.',
    'about_custom_fields_title' => 'À propos des champs personnalisés',
    'about_custom_fields_text' => 'Les champs personnalisés vous permettent d\'ajouter des attributs arbitraires aux actifs.',
    'add_field_to_fieldset' => 'Ajouter un champ au jeu de champs',
    'make_optional' => 'Requis - cliquez pour rendre optionnel',
    'make_required' => 'Facultatif - cliquez pour rendre requis',
    'reorder' => 'Réordonner',
    'db_field' => 'Champ BDD',
    'db_convert_warning' => 'ATTENTION. Ce champ est dans la table personnalisée en tant que <code>:db_column</code> mais devrait être <code>:expected</code>.',
    'is_unique' => 'Cette valeur doit être unique parmi tous les actifs',
    'unique' => 'Unique',
    'display_in_user_view' => 'Permettre à l\'utilisateur de vérifier ces valeurs dans sa page Voir Ressources Affectées',
    'display_in_user_view_table' => 'Visible par l\'utilisateur',
    'auto_add_to_fieldsets' => 'Ajouter ceci automatiquement à tous les nouveaux fieldsets',
    'add_to_preexisting_fieldsets' => 'Ajouter à tous les fieldsets existants',
    'show_in_listview' => 'Afficher par défaut. Les utilisateurs·trices autorisé·es pourront toujours afficher/masquer la colonne à l\'aide du sélecteur',
    'show_in_listview_short' => 'Afficher dans les listes',
    'show_in_requestable_list_short' => 'Afficher dans la liste des actifs demandables',
    'show_in_requestable_list' => 'Afficher la valeur dans la liste des actifs demandables. Les champs chiffrés ne seront pas affichés',
    'encrypted_options' => 'Ce champ est chiffré, donc certaines options d\'affichage ne seront pas disponibles.',

];
