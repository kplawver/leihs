@ignore
Feature: Implement new Group feature

	Background: Provide a minimal lending environment
	        Given inventory pool 'AVZ'

	Scenario: Have multiple groups, lend and return an item
		When I register a new Model 'Olympus PEN E-P2'
		Then no items of that Model should be available in Group 'General'
		 And that model should not be available in any other Group
		Then no items of that Model should be borrowed to any group
		 And no items of that Model should be unborrowable in any group

		When I add 3 items of that Model
		Then 3 items of that Model should be available in Group 'General' only

		When I add a new Group "CAST" to InventoryPool AVZ

		Then 3 items of that Model should be available in Group 'General' only
		 And that model should not be available in any other Group

		When I move one item of that Model from Group "General" to Group "CAST"
		Then 2 items of that Model should be available in Group 'General'
		 And one item of that Model should be available in Group 'CAST'
		 And that model should not be available in any other Group

		Given I have a user "Tomáš" that belongs to Group "CAST"
		When I lend one item of Model "Olympus PEN E-P2" to "Tomáš"
		Then 2 items of that Model should be available in Group 'General'
		 And no items of that Model should be borrowable in Group 'CAST'
		 And no items of that Model should be unborrowable in any group
		 And one item of that Model should be borrowed in Group 'CAST'

		When "Tomáš" returns the item
		Then 2 items of that Model should be available in Group 'General'
		 And one item of that Model should be borrowable in Group 'CAST'

	# this Scenario expands on "Have multiple groups, lend and return an item"
	Scenario: Use the "General" Group as fallback for lending
		Given a model 'Olympus PEN E-P2' exists
		  And a Group "CAST"
		  And a user "Tomáš" that belongs to Group "CAST"
		  And a user "Franco" that belongs to Group "CAST"
		  And 2 items of that Model in Group "CAST"
		  And one item of that Model in the "General" Group

		When I lend 2 items of that Model to "Tomáš"
		 And I lend one item of that Model to "Franco"
		Then 2 items of that Model should be borrowed in Group 'CAST'
		 And one item of that Model should be borrowed in Group 'General'
