# == Participable concern
#
# Contains functionality related to objects that can have participants, such as
# an author, an assignee and people mentioned in its description or comments.
#
# Used by Issue, Note, MergeRequest, Snippet and Commit.
#
# Usage:
#
#     class Issue < ActiveRecord::Base
#       include Participable
#
#       # ...
#
#       participant :author, :assignee, :mentioned_users, :notes
#     end
#     
#     issue = Issue.last
#     users = issue.participants
#     # `users` will contain the issue's author, its assignee,
#     # all users returned by its #mentioned_users method,
#     # as well as all participants to all of the issue's notes,
#     # since Note implements Participable as well.
#
module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    def participant(*attrs)
      participant_attrs.concat(attrs.map(&:to_s))
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  def participants(current_user = self.author)
    self.class.participant_attrs.flat_map do |attr|
      meth = method(attr)

      value = 
        if meth.arity == 1 || meth.arity == -1
          meth.call(current_user)
        else
          meth.call
        end

      participants_for(value, current_user)
    end.compact.uniq
  end

  private
  
  def participants_for(value, current_user = nil)
    case value
    when User
      [value]
    when Enumerable, ActiveRecord::Relation
      value.flat_map { |v| participants_for(v, current_user) }
    when Participable
      value.participants(current_user)
    end
  end
end
