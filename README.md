
How Card Contexts Work
======================

The properties of Cards are much more contextual than I first realized.
- Some properties are invariant of any context, e.g. the number of actions a Village provides (+2).
- Some properties are true for all Cards of a given type, but are dependent on Game state, e.g. the cost of Peddler, or the cost of any Card after Bridge is played.
- Some properties are actually dependent on the instance of the Card itself, e.g. the coins provided by a given Bank card.  You can play two Banks in one hand, and each will provide a different number of coins.

It's convenient (and necessary) to be able to ask any Card instance for its cost.  However, it's also convenient to be able to ask about the cost of "Peddler", without referring to any particular instance.  Note that this is still dependent on Game state.

How should we setup the contexts and dependencies for this kind of thing.  Ideally, I'd like to be able to say:  Peddler.cost, but that may not really be possible.  Imagine two games in progress at the same time.  What value should Peddler.cost return?

My compromise is the following:
Peddler.cost always returns 8.
However, peddler.cost (where peddler is an instance of Peddler), will return a contextual cost.
All cards have a context, which can be a Player or a Game instance.

The rules for cards refer to a number of properties and verbs, like 'deck', 'trash', 'supply', 'gain', etc.  Ideally the DSL for each Card should use these same terms.

Peddler.new will return a Peddler instance with no context (actually its context defaults to Game::BASE_CONTEXT).

When evaluating various buy rules, it's convenient to refer to "Peddler", not to a given Peddler instance, but as mentioned above, that's not really possible because of the dependence on game context.

Two options are available:

- Use Peddler.new(game)
- Use something like game.supply_piles[Peddler].first

The first approach basically conjures a new card instance from thin air, and pretends it's part of the current game.
The second approach is attractive, because it does refer to the card instance you would actually buy, without any artificial contexts running around.  You can never buy "Peddler".  You can just buy "that Peddler in the supply".  That's pretty slick.  I'll run with that and see how far I get.  There may still be times when the buy rules would like to refer to the Peddlers that aren't actually available in the supply.  For those rare occurrences, there's always option #1.


Card Contexts:

- Owned by a player (in hand, deck, discard, etc)
- In game, but not by a player (in supply, trash, etc)
- Not in game (while randomizing, picking rules, documentation of cards, etc)

Abstractly, all card instances have a context, even that last bit, which is essentially a game in a special phase.

When method_missing is called on a Card instance, it defers first to the Card's class, if it responds to the method.  This lets the Card class be a prototype for all instances, for a number of very common properties, which are independent of any context.  e.g. cost, actions, buys, etc. for most cards.

If the Card class does not respond to the missing method, then the 'context' is called.  This context is duck-typed.  It may be a Player, a Game in progress, or the Game::BASE_CONTEXT instance, which is basically a dummy game not being played.  This is useful when you want to just ask "How much does Peddler cost?".


So, the chain of command looks something like this:

- Card instance
- Card class
- Player instance  (optional)
- Game instance
- Game::BASE_CONTEXT

Seem complex?  It is.  Unfortunately, that's the best I can come up with, as a place to put each rule, to cover the myriad complexities of the game, and I haven't even thought about coding Possession yet!

Luckily, the mechanism defined in Card makes most of this transparent.  Check out cards.rb to see the DSL in practice.


                   Card.class
                        ^
                        |
    Game <- Player <- Card
      ^                 |
      +-----------------+


    peddler
      class = Peddler
        superclass = Card
      context = instance of Player or Game


Player vs PlayerIdentity
========================

A Player is a member of a Game.  A PlayerIdentity is more like a login on isotropic.
The main reason for the distinction is so a single PlayerIdentity can play two Games at once.
It's also convenient to have a Player with no PlayerIdentity, meaning an anonymous Player.
Card rules should refer to Player, and never to PlayerIdentity.  (Man, that would be some duration card.)


Where can Cards live?
=====================

- No Context (Card::BASE_CONTEXT)
+ Game
  - supply
  - trash_pile
  + Player
    - actions_in_play
    - durations_on_first_turn  (Lighthouse, Caravan, Haven, etc)
    - treasures_in_play
    - hand
    - deck
    - discard_pile
    - various mats (Island, NativeVillage, etc)

What about a KingsCourt played on a duration card like Caravan?  The KingsCourt becomes a duration_in_play, just like the Caravan itself.  Note that Player.durations_on_first_turn will contain the KingsCourt, not the Caravan, and the KingsCourt contains a reference to the Caravan.  In fact, the KingsCourt 'remembers' which cards were played, for just these occasions.  You don't get to re-choose which 3 cards to play when replaying a durationized KingsCourt.  The fact that you chose to KingsCourt a KingsCourt, then choose two 2 Caravans, and a non-duration card are set in stone on the first play.


Game State Machine
==================

This is as good a time as any to think through the various game states, and their corresponding hooks on cards.

Hooks:

- on_play                   (called when this card is played)
- on_buy                    (called when this card is bought)
- on_gain                   (called when this card is gained or bought)
- on_discard                (called when this card is discarded)
- on_trash                  (called when this card is trashed)
- on_attack                 (called when this card is in hand of an attacked player)
- on_any_card_gained        (called when this card is in hand of any player, and any card is gained by any player)
- on_setup_after_duration   (called when this card is brought back into the hand after a duration)

The buy hooks are only called when the card is actually bought in the buy phase.
The gain hooks are called both on buy and when the card is gained in other manners.
Typically, a card won't define both the buy and gain hooks, but for clarity, they are both called, and in the order 'buy' then 'gain'.



The rule books say treasures are played in the 'buy' phase, but then they go to great lengths to say that you must play all treasures before doing any buys.

My design separates the treasure/buy phases, and works like this:

- actions are played in the action phase
- treasures are played in the treasure phase
- buys are done in the buy phase

See how easy it is when you just name things correctly?

The action phase is when most action cards have an effect.  e.g. this is when a Village actually gives you +2 actions and +1 card.  The 'on_play' hook is called after the statically defined properties are resolved, e.g. +1 card/+1 action.

The treasure phase is when treasures are played.
The 'play_treasure' hook is called when a treasure card is played, and after any statically defined properties are resolved, e.g. +1 coin for Copper.  Most simple treasures do not override the 'play_treasure' hook.
Cards like Venture, Loan, and Contraband, however, are considerably more complex.

The buy phase is when cards are actually bought.
on_buy is called when a card is bought.  This is useful for validating the purchase of a GrandMarket, for example.

This should not be confused with on_any_card_bought, which is called on all cards in play any time a card is bought.  This is sometimes useful for validations of a purchase, such as Contraband.

on_any_card_gained is useful for reactions, such as Watchtower.

We'll need an on_shuffle in order to handle Stash.  But of course, that means that every draw can block.  I don't really like Stash anyway.  Maybe just skip it.  Same goes for Possession.  :)


Reactions
=========

Reactions are interesting.  There are several kinds of reaction:
- attack (Moat, Secret Chamber, Horse Traders)
- self gain (Watchtower, Trader)
- other's gain (Fool's Gold)
- discard (Tunnel)

Attack reactions are resolved as the card is played, before actually taking any action.  So, other players reveal Moat as an attack card is played, even if it's a Minion or Pirate Ship, and the player chooses to take the coins instead of attacking.

Self gain reactions have the ability to change where the card goes (Watchtower), and what card is gained (Trader).

Fool's Gold has to monitor the gains of other player's cards, to offer a choice to be trashed for a Gold when another player gains a Province.

Reactions are designed to be idempotent:
- Moat - Doesn't matter how many times you play it.  It stops the attack.
- Watchtower - You can only pick one: trash or deck (you can also choose not reveal it) 
- Secret Chamber is the most complex.  You can play it in response to an attack, find a Moat among the next two cards, then play the Moat, and prevent the attack.  Then play the Secret Chamber again, and put the Moat back on your deck.  Wow.
- Horse Traders is set aside when it's played as a reaction, so you can't play it more than once
- Tunnel leaves the hand, as well
- Fool's Gold is trashed, so it's no longer in hand

Trader and Watchtower can be combined, to gain a Silver, and put it on your deck
Isotropic continues to ask about reactions until you say 'no', due to the stuff about Secret Chamber.  We can probably do better than that, and only ask about the Moat if you haven't already revealed it.  Maybe only repeatedly ask when there's a Secret Chamber in play, too.


Examples:

- PlayerA plays a Witch during their action phase
- PlayerB has a Watchtower in hand, and a Lighthouse in play
- When the Witch is played, before executing it, go through the other players, and ask to reveal any reactions
- Don't bother asking about the Moat if attack_prevented is true (in this case because of Lighthouse, but it might be because Moat was already played.  This extra rule just makes reactions less annoying)

- There are five possible outcomes here:
  1. PlayerB previously played Lighthouse, attack is unsuccessful, Curse stays in supply
  2. PlayerB didn't play Lighthouse, PlayerB reveals Watchtower and chooses trash, Curse is trashed
  3. PlayerB didn't play Lighthouse, PlayerB reveals Watchtower and chooses deck, Curse is gained to deck
  4. PlayerB didn't play Lighthouse, PlayerB doesn't reveal Watchtower, Curse is gained to discard
  5. Curse supply pile is empty - attack may still occur (so other reactions may still apply), but no Curse is gained

Note that 1 and 2 are different, because a Curse is trashed in 2, but left in the supply in 1.
If Moat and Watchtower are both in hand, you can choose which to reveal first.  I have no idea how I'm going to program a computer to make this choice intelligently.  :)


Inversion of Control
====================

Who calls what?  Does the game call a player, and ask them to make a choice?  Does the game just sit there,
and let the player call it?  In some respects it seems like having the game call the player is appropriate,
but if I ever want this to be asynchronous (e.g. run a server like isotropic), then I'll need a way to
avoid saving all of this state on the call stack, and instead keep it in the game state.  That suggests
a design more like the latter, where the game just sits there, waiting for methods to be called on it.
This latter design is definitely more complicated.  It make reactions and the like very complicated.

Maybe I can start simpler, by having the game call the players, and then later, if there's ever a need
to make the program truly asynchronous, go back and put the state into the cards/game, rather than in the
call stack.

Players need a proxy, so human vs simulator can be easily plugged in.  Every time the player has to make
a choice, it can call out to the proxy.

Addendum:  I found a better way to handle this.  Use fibers in the player strategy, so that the rest of the code uses straight up synchronous calling style.  Keeps it much cleaner.

