#include "hulaoguan-scenario.h"
#include "engine.h"
#include "standard-skillcards.h"
#include "clientplayer.h"
#include "client.h"
#include "carditem.h"

class HulaoguanRule: public ScenarioRule {
public:
    HulaoguanRule(Scenario *scenario)
        :ScenarioRule(scenario)
    {
        events << GameStart << Death << GameOverJudge << TurnStart;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const{
        Room *room = player->getRoom();

        switch(event){
        case GameStart:
        {
            switch(player->getSeat()) {
            case 0:
                room->transfigure(player, "hu_lubu_1", true, true);
                player->drawCards(8, false);
                return true;
            }
            break;
        }

        default:
            break;

        }

        return false;
    }
};

XiuluoCard::XiuluoCard() {
    target_fixed = true;
}

void XiuluoCard::use(Room *room, ServerPlayer *source, const QList<ServerPlayer *> &targets) const {

}

class Xiuluo : public OneCardViewAsSkill {
public:
    Xiuluo() : OneCardViewAsSkill("xiuluo") { }

    virtual bool viewFilter(const CardItem *to_select) const {
        return true;
    }

    virtual const Card *viewAs(CardItem *card_item) const {
        XiuluoCard *skill_card = new XiuluoCard;
        skill_card->setSkillName("xiuluo");
        return skill_card;
    }
};

class Shenwei : public TriggerSkill {
public:
    Shenwei():TriggerSkill("shenwei"){
        events << PhaseChange;

        frequency = Compulsory;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const {
        if(player->getPhase() == Player::Draw)
            player->drawCards(2);

        return false;
    }
};

bool HulaoguanScenario::exposeRoles() const{
    return true;
}

void HulaoguanScenario::assign(QStringList &generals, QStringList &roles) const{
    Q_UNUSED(generals);

    roles << "lord";
    int i;
    for(i=0; i<3; i++)
        roles << "rebel";

    qShuffle(roles);
}

int HulaoguanScenario::getPlayerCount() const{
    return 4;
}

void HulaoguanScenario::getRoles(char *roles) const{
    strcpy(roles, "ZFFF");
}

void HulaoguanScenario::onTagSet(Room *room, const QString &key) const{
    // dummy
}

bool HulaoguanScenario::generalSelection() const{
    return true;
}

HulaoguanScenario::HulaoguanScenario()
    :Scenario("hulaoguan_mode")
{
    rule = new HulaoguanRule(this);

    General *hulaoguan_lvbu_1 = new General(this, "hu_lubu_1", "god", 8, true, true);
    hulaoguan_lvbu_1->addSkill("wushuang");
    hulaoguan_lvbu_1->addSkill("mashu");

    General *hulaoguan_lvbu_2 = new General(this, "hu_lubu_2", "god", 4, true, true);
    hulaoguan_lvbu_2->addSkill("wushuang");
    hulaoguan_lvbu_2->addSkill("mashu");
    hulaoguan_lvbu_2->addSkill(new Xiuluo);
    hulaoguan_lvbu_2->addSkill(new Shenwei);
    hulaoguan_lvbu_2->addSkill("shenji");

    addMetaObject<XiuluoCard>();
}

ADD_SCENARIO(Hulaoguan)
