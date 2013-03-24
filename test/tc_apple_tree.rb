class TestAppleTree < Test::Unit::TestCase
  def test_init
    at = AppleTree.new [ "red", nil, 5 ]
    assert_instance_of AppleTree, at
    assert_respond_to at, :pk
    assert_nil at.pk
    at.save
    at_db = Ink::Database.database.find(AppleTree, "WHERE #{AppleTree.primary_key}=#{Ink::Database.database.last_inserted_pk(AppleTree)}").first
    assert_equal at.color, at_db.color
    assert_equal at.note, at_db.note
    assert_equal at.height, at_db.height
    assert_equal at.id, at_db.id
    at.height = 10
    at.save
    assert_not_equal at.height, at_db.height
  end

  def test_one_many
    at = AppleTree.new [ "red", nil, 5 ]
    at.save
    w = Wig.new "length" => 15
    w.apple_tree = at
    w.save
    at.find_references Wig
    assert_equal at.wig.first.ref, w.ref
    at.wig = []
    at.save
    w.find_references AppleTree
    assert_nil w.apple_tree
  end

  def test_many_many
    at = AppleTree.new [ "red", nil, 5 ]
    at.save
    at2 = AppleTree.new [ "green", "comment", 6 ]
    at2.save
    cs = ColorSpray.new "color" => "blue"
    cs.apple_tree = at
    cs.save
    at2.color_spray = cs
    at2.save
    cs.find_references AppleTree
    assert_equal cs.apple_tree.length, 2
  end

  def test_statics
    assert_equal AppleTree.foreign_key_type, "INTEGER"
    assert_equal AppleTree.foreign_key, "apple_tree_id"
    assert_equal Wig.foreign_key, "wig_ref"
    assert_equal AppleTree.primary_key_type, "INTEGER"
    assert_equal AppleTree.primary_key, :id
    assert_equal Ink::Model.classname("apple_tree"), AppleTree
    assert_equal Ink::Model.classname("wig"), Wig
    assert_equal Ink::Model.str_to_tablename("AppleTree"), "apple_tree"
    assert_equal Ink::Model.str_to_tablename("Wig"), "wig"
    assert_equal Ink::Model.str_to_classname("apple_tree"), "AppleTree"
    assert_equal Ink::Model.str_to_classname("wig"), "Wig"
    assert_equal AppleTree.table_name, "apple_tree"
    assert_equal Wig.table_name, "wig"
    assert_equal AppleTree.class_name, "AppleTree"
    assert_equal Ink::Database.database.last_inserted_pk(Wig), 1
  end
end
